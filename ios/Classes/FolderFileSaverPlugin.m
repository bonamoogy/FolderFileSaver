#import "FolderFileSaverPlugin.h"
#import <folder_file_saver/folder_file_saver-Swift.h>

@implementation FolderFileSaverPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFolderFileSaverPlugin registerWithRegistrar:registrar];
}
@end
