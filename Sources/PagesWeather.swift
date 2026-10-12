import AppKit
import SwiftUI
import Combine
import UniformTypeIdentifiers
import ImageIO
import ServiceManagement
import ApplicationServices
import CoreAudio
import IOKit
import Foundation

// MARK: - 天气数据模型

struct GeoResult: Decodable {
    struct Place: Decodable {
        let latitude: Double
        let longitude: Double
        let name: String?
        let country: String?
        let admin1: String?
    }
    let results: [Place]?
}

struct WeatherForecast: Decodable {
    struct Current: Decodable {
        let temperature2m: Double
        let apparentTemperature: Double
        let humidity: Double
        let weatherCode: Int
        let windSpeed: Double
        let isDay: Int
        enum CodingKeys: String, CodingKey {
            case temperature2m = "temperature_2m"
            case apparentTemperature = "apparent_temperature"
            case humidity = "relative_humidity_2m"
            case weatherCode = "weather_code"
            case windSpeed = "wind_speed_10m"
            case isDay = "is_day"
        }
    }
    struct Daily: Decodable {
        let time: [String]
        let weatherCode: [Int]
        let tempMax: [Double]
        let tempMin: [Double]
        enum CodingKeys: String, CodingKey {
            case time
            case weatherCode = "weather_code"
            case tempMax = "temperature_2m_max"
            case tempMin = "temperature_2m_min"
        }
    }
    let current: Current
    let daily: Daily
}

struct AirQualityData: Decodable {
    struct Current: Decodable {
        let usAqi: Double?
        let pm25: Double?
        let pm10: Double?
        enum CodingKeys: String, CodingKey {
            case usAqi = "us_aqi"
            case pm25 = "pm2_5"
            case pm10 = "pm10"
        }
    }
    let current: Current
}

struct WeatherData {
    let forecast: WeatherForecast
    let air: AirQualityData?
}

func weatherInfo(for code: Int) -> (icon: String, desc: String) {
    switch code {
    case 0: return ("sun.max.fill", "晴")
    case 1: return ("sun.max.fill", "大部晴朗")
    case 2: return ("cloud.sun.fill", "多云")
    case 3: return ("cloud.fill", "阴")
    case 45, 48: return ("cloud.fog.fill", "雾")
    case 51, 53, 55: return ("cloud.drizzle.fill", "毛毛雨")
    case 56, 57: return ("cloud.sleet.fill", "冻雨")
    case 61, 63, 65: return ("cloud.rain.fill", "雨")
    case 66, 67: return ("cloud.sleet.fill", "冻雨")
    case 71, 73, 75: return ("cloud.snow.fill", "雪")
    case 77: return ("snowflake", "雪粒")
    case 80, 81, 82: return ("cloud.heavyrain.fill", "阵雨")
    case 85, 86: return ("cloud.snow.fill", "阵雪")
    case 95: return ("cloud.bolt.rain.fill", "雷暴")
    case 96, 99: return ("cloud.bolt.rain.fill", "雷暴冰雹")
    default: return ("cloud.fill", "未知")
    }
}

func aqiLevel(_ aqi: Double) -> (label: String, color: Color) {
    switch aqi {
    case ..<51: return ("优", .green)
    case ..<101: return ("良", .yellow)
    case ..<151: return ("轻度污染", .orange)
    case ..<201: return ("中度污染", .red)
    case ..<301: return ("重度污染", .purple)
    default: return ("严重污染", Color(red: 0.62, green: 0.22, blue: 0.22))
    }
}

// MARK: - 天气拉取（扩展 AppState）

extension AppState {
    private static let weatherWeekdays = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]

    static func weatherDayLabel(_ iso: String, index: Int) -> String {
        if index == 0 { return "今天" }
        let parts = iso.split(separator: "-")
        guard parts.count == 3, let y = Int(parts[0]), let m = Int(parts[1]), let d = Int(parts[2]) else { return iso }
        var comps = DateComponents()
        comps.year = y; comps.month = m; comps.day = d
        guard let date = Calendar.current.date(from: comps) else { return iso }
        let wd = Calendar.current.component(.weekday, from: date)
        return weatherWeekdays[wd - 1]
    }

    func fetchWeather(force: Bool = false) {
        if !force, let last = weatherLastFetch, Date().timeIntervalSince(last) < 600, weatherData != nil {
            return
        }
        weatherFetchTask?.cancel()
        let city = weatherCity.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !city.isEmpty else {
            weatherError = "请先在页面右上角设置城市"
            return
        }
        weatherLoading = true
        weatherError = ""
        let enc = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
        guard let geoURL = URL(string: "https://geocoding-api.open-meteo.com/v1/search?name=\(enc)&count=1&language=zh&format=json") else {
            weatherLoading = false
            weatherError = "城市名称无效"
            return
        }
        weatherFetchTask = URLSession.shared.dataTask(with: geoURL) { [weak self] data, _, err in
            guard let self = self else { return }
            if let err = err {
                self.finishWeather(.failure(.network(err.localizedDescription)))
                return
            }
            guard let data = data,
                  let geo = try? JSONDecoder().decode(GeoResult.self, from: data),
                  let first = geo.results?.first else {
                self.finishWeather(.failure(.message("未找到城市「\(city)」，请检查名称")))
                return
            }
            self.fetchWeatherForecast(lat: first.latitude, lon: first.longitude)
        }
        weatherFetchTask?.resume()
    }

    private enum WeatherFetchError: Error {
        case network(String)
        case message(String)
    }

    private func fetchWeatherForecast(lat: Double, lon: Double) {
        let fcURL = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m,is_day&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=7"
        let aqURL = "https://air-quality-api.open-meteo.com/v1/air-quality?latitude=\(lat)&longitude=\(lon)&current=us_aqi,pm2_5,pm10&timezone=auto"
        guard let fcU = URL(string: fcURL), let aqU = URL(string: aqURL) else {
            finishWeather(.failure(.message("请求地址无效")))
            return
        }
        var forecast: WeatherForecast?
        var air: AirQualityData?
        let group = DispatchGroup()
        var firstErr: WeatherFetchError?

        group.enter()
        URLSession.shared.dataTask(with: fcU) { data, _, err in
            defer { group.leave() }
            if let err = err { firstErr = firstErr ?? .network(err.localizedDescription); return }
            if let data = data, let fc = try? JSONDecoder().decode(WeatherForecast.self, from: data) {
                forecast = fc
            } else {
                firstErr = firstErr ?? .message("预报数据解析失败")
            }
        }.resume()

        group.enter()
        URLSession.shared.dataTask(with: aqU) { data, _, err in
            defer { group.leave() }
            if let err = err { firstErr = firstErr ?? .network(err.localizedDescription); return }
            if let data = data, let aq = try? JSONDecoder().decode(AirQualityData.self, from: data) {
                air = aq
            }
        }.resume()

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            if let err = firstErr {
                self.finishWeather(.failure(err))
                return
            }
            guard let fc = forecast else {
                self.finishWeather(.failure(.message("天气数据为空")))
                return
            }
            self.weatherData = WeatherData(forecast: fc, air: air)
            self.weatherLastFetch = Date()
            self.weatherLoading = false
            self.weatherError = ""
        }
    }

    private func finishWeather(_ result: Result<Void, WeatherFetchError>) {
        DispatchQueue.main.async {
            if case .failure(let err) = result {
                switch err {
                case .network(let msg): self.weatherError = "网络错误：\(msg)"
                case .message(let msg): self.weatherError = msg
                }
            }
            self.weatherLoading = false
        }
    }
}

// MARK: - 天气页面

struct WeatherPageView: View {
    @ObservedObject var state: AppState
    @State private var editingCity = false

    private var data: WeatherData? { state.weatherData }

    var body: some View {
        VStack(spacing: 8) {
            header
            if state.weatherLoading && data == nil {
                HStack(spacing: 8) {
                    ActivitySpinner()
                    Text("获取天气中…").font(.system(size: tfs(9))).foregroundColor(.white.opacity(0.6))
                }
                .frame(maxHeight: .infinity)
            } else if let err = state.weatherError.isEmpty ? nil : state.weatherError, data == nil {
                VStack(spacing: 8) {
                    sysImage("wifi.exclamationmark").font(.system(size: tfs(22))).foregroundColor(.white.opacity(0.35))
                    Text(err).font(.system(size: tfs(9))).foregroundColor(.white.opacity(0.55)).multilineTextAlignment(.center)
                    Button { state.fetchWeather(force: true) } label: {
                        Text("重试").font(.system(size: tfs(9), weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14).padding(.vertical, 5)
                            .background(Capsule().fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(PressBtn())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let d = data {
                currentBlock(d)
                if !state.isBlockHidden("daily") { dailyStrip(d) }
                if !state.isBlockHidden("air"), let air = d.air { airCard(air) }
                Spacer(minLength: 0)
            } else {
                Text("点击右上角刷新获取天气").font(.system(size: tfs(9))).foregroundColor(.white.opacity(0.45))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { state.fetchWeather() }
    }

    // MARK: 头部：城市 + 编辑 + 刷新
    private var header: some View {
        HStack(spacing: 6) {
            sysImage("location.fill")
                .font(.system(size: tfs(9)))
                .foregroundColor(.white.opacity(0.55))
            if editingCity {
                TextField("输入城市", text: $state.weatherCity)
                    .textFieldStyle(.plain)
                    .font(.system(size: tfs(10), weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 110)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: rr(6)).fill(Color.white.opacity(0.12)))
                    .onSubmit { editingCity = false; state.fetchWeather(force: true) }
                Button {
                    editingCity = false
                    state.fetchWeather(force: true)
                } label: {
                    sysImage("checkmark.circle.fill").font(.system(size: tfs(11))).foregroundColor(.green)
                }
                .buttonStyle(PressBtn())
            } else {
                Text(state.weatherCity)
                    .font(.system(size: tfs(11), weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                if state.weatherLoading {
                    ActivitySpinner().scaleEffect(0.7)
                }
            }
            Spacer()
            Button { editingCity.toggle() } label: {
                sysImage(editingCity ? "xmark.circle.fill" : "pencil.circle.fill")
                    .font(.system(size: tfs(11)))
                    .foregroundColor(.white.opacity(0.5))
            }
            .buttonStyle(PressBtn())
            Button { state.fetchWeather(force: true) } label: {
                sysImage("arrow.clockwise.circle.fill")
                    .font(.system(size: tfs(12)))
                    .foregroundColor(.white.opacity(0.6))
            }
            .buttonStyle(PressBtn())
        }
    }

    // MARK: 当前实况
    private func currentBlock(_ d: WeatherData) -> some View {
        let c = d.forecast.current
        let info = weatherInfo(for: c.weatherCode)
        return HStack(spacing: 12) {
            HStack(spacing: 8) {
                sysImage(info.icon)
                    .font(.system(size: tfs(30)))
                    .foregroundColor(c.isDay == 1 ? .yellow : .white.opacity(0.85))
                    .shadow(color: c.isDay == 1 ? .yellow.opacity(0.45) : .clear, radius: 6)
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(Int(c.temperature2m))°")
                        .font(.system(size: tfs(30), weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(info.desc)
                        .font(.system(size: tfs(9)))
                        .foregroundColor(.white.opacity(0.55))
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                metric("thermometer.medium", "体感 \(Int(c.apparentTemperature))°")
                metric("humidity.fill", "湿度 \(Int(c.humidity))%")
                metric("wind", "\(Int(c.windSpeed)) km/h")
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: rr(12)).fill(Color.white.opacity(0.07)))
    }

    private func metric(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 4) {
            sysImage(icon).font(.system(size: tfs(8))).foregroundColor(.white.opacity(0.4))
            Text(text).font(.system(size: tfs(8.5))).foregroundColor(.white.opacity(0.7))
        }
    }

    // MARK: 未来 7 天轨迹
    private func dailyStrip(_ d: WeatherData) -> some View {
        let days = d.forecast.daily
        let count = min(days.time.count, days.weatherCode.count)
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(0..<count, id: \.self) { i in
                    let info = weatherInfo(for: days.weatherCode[i])
                    VStack(spacing: 3) {
                        Text(AppState.weatherDayLabel(days.time[i], index: i))
                            .font(.system(size: tfs(8.5)))
                            .foregroundColor(i == 0 ? .white : .white.opacity(0.6))
                        sysImage(info.icon)
                            .font(.system(size: tfs(14)))
                            .foregroundColor(.white.opacity(0.85))
                        HStack(spacing: 3) {
                            Text("\(Int(days.tempMax[i]))°").font(.system(size: tfs(8.5), weight: .semibold)).foregroundColor(.white.opacity(0.9))
                            Text("\(Int(days.tempMin[i]))°").font(.system(size: tfs(8.5))).foregroundColor(.white.opacity(0.4))
                        }
                    }
                    .frame(width: 44)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: rr(8))
                            .fill(i == 0 ? Color.white.opacity(0.12) : Color.white.opacity(0.05))
                    )
                }
            }
            .padding(.horizontal, 2)
        }
        .frame(height: 62)
    }

    // MARK: 空气质量
    private func airCard(_ air: AirQualityData) -> some View {
        let aqi = air.current.usAqi ?? 0
        let lv = aqiLevel(aqi)
        return HStack(spacing: 8) {
            sysImage("aqi.medium")
                .font(.system(size: tfs(14)))
                .foregroundColor(lv.color)
            VStack(alignment: .leading, spacing: 1) {
                Text("空气质量 \(Int(aqi)) · \(lv.label)")
                    .font(.system(size: tfs(9), weight: .semibold))
                    .foregroundColor(lv.color)
                if let pm = air.current.pm25, let p10 = air.current.pm10 {
                    Text("PM2.5 \(Int(pm)) μg/m³ · PM10 \(Int(p10)) μg/m³")
                        .font(.system(size: tfs(8)))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            Spacer()
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: rr(12)).fill(Color.white.opacity(0.07)))
    }
}

// MARK: - 仪表盘天气走势小组件（近 7 天，点击跳转天气页）

struct DashboardWeatherStrip: View {
    @ObservedObject var state: AppState
    private var weatherPage: Int {
        state.displayPosition(of: 8)
    }

    var body: some View {
        Group {
            if let fc = state.weatherData?.forecast, fc.daily.time.count > 0 {
                content(fc: fc)
            } else {
                guide
            }
        }
        .frame(height: 46)
    }

    private func content(fc: WeatherForecast) -> some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 1) {
                Text(state.weatherCity)
                    .font(.system(size: tfs(7.5), weight: .medium))
                    .foregroundColor(.white.opacity(0.45))
                    .lineLimit(1)
                HStack(spacing: 3) {
                    sysImage(weatherInfo(for: fc.current.weatherCode).icon)
                        .font(.system(size: tfs(13)))
                        .foregroundColor(.white.opacity(0.9))
                    Text("\(Int(fc.current.temperature2m.rounded()))°")
                        .font(.system(size: tfs(15), weight: .bold))
                        .foregroundColor(.white)
                }
                Text(weatherInfo(for: fc.current.weatherCode).desc)
                    .font(.system(size: tfs(7)))
                    .foregroundColor(.white.opacity(0.35))
                    .lineLimit(1)
            }
            .frame(width: 76, alignment: .leading)

            Divider().frame(height: 30).overlay(Color.white.opacity(0.12))

            HStack(spacing: 3) {
                let hi = fc.daily.tempMax
                let lo = fc.daily.tempMin
                let top = hi.max() ?? 35
                let bottom = min(lo.min() ?? 0, top)
                let span = max(top - bottom, 1)
                ForEach(Array(fc.daily.time.enumerated()), id: \.offset) { i, iso in
                    let wc = fc.daily.weatherCode[i]
                    VStack(spacing: 1) {
                        Text(AppState.weatherDayLabel(iso, index: i))
                            .font(.system(size: tfs(6), weight: i == 0 ? .semibold : .regular))
                            .foregroundColor(i == 0 ? .white.opacity(0.85) : .white.opacity(0.4))
                        sysImage(weatherInfo(for: wc).icon)
                            .font(.system(size: tfs(8)))
                            .foregroundColor(.white.opacity(0.85))
                        ZStack(alignment: .bottom) {
                            Capsule().fill(Color.white.opacity(0.10)).frame(width: 4, height: 10)
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.35, green: 0.85, blue: 1.0).opacity(0.95),
                                                 Color(red: 1.0, green: 0.62, blue: 0.35).opacity(0.9)],
                                        startPoint: .bottom, endPoint: .top
                                    )
                                )
                                .frame(width: 4, height: max(3, 10 * CGFloat((hi[i] - bottom) / span)))
                        }
                        .frame(height: 10)
                        Text("\(Int(hi[i].rounded()))°")
                            .font(.system(size: tfs(6), weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 8).padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: rr(10))
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
        )
        .overlay(RoundedRectangle(cornerRadius: rr(10)).stroke(Color.white.opacity(0.05), lineWidth: 0.5))
        .contentShape(Rectangle())
        .onTapGesture { state.currentPage = weatherPage }
        .helpAny("查看详细天气")
    }

    private var guide: some View {
        HStack(spacing: 5) {
            sysImage("cloud.sun.fill")
                .font(.system(size: tfs(10)))
                .foregroundColor(.white.opacity(0.4))
            Text(state.weatherLoading ? "天气加载中…" :
                 (state.weatherError.isEmpty ? "未获取到天气数据" : "天气数据暂不可用"))
                .font(.system(size: tfs(8)))
                .foregroundColor(.white.opacity(0.4))
            Spacer()
            Text("去天气页设置")
                .font(.system(size: tfs(7.5)))
                .foregroundColor(.cyan.opacity(0.85))
        }
        .padding(.horizontal, 9).padding(.vertical, 3)
        .background(RoundedRectangle(cornerRadius: rr(8)).fill(Color.white.opacity(0.04)))
        .contentShape(Rectangle())
        .onTapGesture { state.currentPage = weatherPage }
    }
}
