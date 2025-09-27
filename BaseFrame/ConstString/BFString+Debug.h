//
//  BFString+Debug.h
//  MoQia
//
//  Created by 王祥伟 on 2024/7/10.
//

#import "BFString.h"

NS_ASSUME_NONNULL_BEGIN

@interface BFString (Debug)

///debug工具页面
+ (NSString *)vc_log;
+ (NSString *)vc_font;
+ (NSString *)vc_file;
+ (NSString *)vc_file_data;
+ (NSString *)vc_log_detail;
+ (NSString *)vc_leaks;
+ (NSString *)vc_crash;
+ (NSString *)vc_monitor;
+ (NSString *)vc_app_info;
+ (NSString *)vc_app_detail;
+ (NSString *)vc_po_object;
+ (NSString *)vc_json_object;
+ (NSString *)vc_shot_object;
+ (NSString *)vc_debug_tool;
+ (NSString *)vc_debug_switch;
+ (NSString *)vc_ui_hierarchy;
+ (NSString *)vc_user_defaults;
+ (NSString *)vc_network_monitor;
+ (NSString *)vc_confound;
+ (NSString *)vc_spam_code;
+ (NSString *)vc_spam_code_model;
+ (NSString *)vc_spam_code_method;
+ (NSString *)vc_spam_code_word;
+ (NSString *)vc_modify_project;
+ (NSString *)vc_modify_class;
+ (NSString *)vc_fast_point;
+ (NSString *)vc_router;
+ (NSString *)vc_router_params;

//tableViewCell ===========================================================================
+ (NSString *)tc_log;
+ (NSString *)tc_font;
+ (NSString *)tc_leaks;
+ (NSString *)tc_crash;
+ (NSString *)tc_monitor;
+ (NSString *)tc_po_object;
+ (NSString *)tc_json_object;
+ (NSString *)tc_app_info;
+ (NSString *)tc_file;
+ (NSString *)tc_file_data;
+ (NSString *)tc_debug_switch;
+ (NSString *)tc_ui_hierarchy;
+ (NSString *)tc_user_defaults;
+ (NSString *)tc_router_params;
+ (NSString *)tc_analysis_click;
+ (NSString *)tc_network_monitor;
+ (NSString *)tc_confound;
+ (NSString *)tc_spam_code_model;
+ (NSString *)tc_confound_label;
+ (NSString *)tc_router;

///其他类 ===========================================================================
+ (NSString *)bf_debug_tool;
@end

NS_ASSUME_NONNULL_END
