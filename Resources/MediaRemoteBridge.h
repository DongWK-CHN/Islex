#import <Foundation/Foundation.h>

typedef void (^MRNowPlayingInfoHandler)(NSDictionary *information);
typedef void (^MRPlayingHandler)(BOOL isPlaying);
typedef void (^MRStringHandler)(NSString *string);

extern void MRMediaRemoteRegisterForNowPlayingNotifications(dispatch_queue_t queue);
extern void MRMediaRemoteGetNowPlayingInfo(dispatch_queue_t queue, MRNowPlayingInfoHandler handler);
extern void MRMediaRemoteGetNowPlayingApplicationIsPlaying(dispatch_queue_t queue, MRPlayingHandler handler);
extern void MRMediaRemoteSendCommand(int command, NSDictionary *payload);
extern void MRMediaRemoteSetElapsedTime(double time);
