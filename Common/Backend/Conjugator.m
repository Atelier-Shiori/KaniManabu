//
//  Conjugator.m
//  conjugator
//
//  Created by 千代田桃 on 5/3/22.
//

#import "Conjugator.h"
@interface Conjugator ()
@property (strong) NSDictionary *conjugationTypes;
@property (strong) NSArray *conjugverbData;
@property (strong) NSArray *conjugadjData;
@end

@implementation Conjugator
NSString *const kConjHigraganaSet = @"るうつむぶぬくぐすいな";
- (instancetype)init {
    if (self = [super init]) {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"conjugationdata" ofType:@"json"];
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        if (json) {
            self.conjugationTypes = json[@"types"];
            self.conjugverbData = json[@"verb_conj_data"];
            self.conjugadjData = json[@"adj_conj_data"];
        }
        else {
            // Failed to load conjugation data.
            [NSException raise:@"Unable to load Conjugation Data" format:@"conjugationdata.json missing from bundle."];
            return nil;
        }
        return self;
    }
    return nil;
}

- (NSDictionary *)getTypesDictionary {
    return _conjugationTypes;
}

- (NSDictionary *)conjugateWord:(NSString *)word {
    NSString *lasttwochars = [word substringFromIndex:word.length - 2];
    NSCharacterSet *conjkanaset = [NSCharacterSet characterSetWithCharactersInString:kConjHigraganaSet];
    NSRange r = [[lasttwochars substringFromIndex:lasttwochars.length-1] rangeOfCharacterFromSet:conjkanaset];
    if (r.location != NSNotFound) {
        NSString *verbending = [lasttwochars substringFromIndex:lasttwochars.length-1];
        NSString *type = @"";
        if ([verbending isEqualToString:@"る"] && ![lasttwochars isEqualToString:@"する"] && ![lasttwochars isEqualToString:@"くる"]&& ![lasttwochars isEqualToString:@"来る"]) {
            if ([lasttwochars isEqualToString:@"ある"] || [lasttwochars isEqualToString:@"有る"]){
                type = @"aru";
            }
            else if ([lasttwochars isEqualToString:@"える"] || [lasttwochars isEqualToString:@"べる"] || [lasttwochars isEqualToString:@"へる"] || [lasttwochars isEqualToString:@"れる"] || [lasttwochars isEqualToString:@"める"] || [lasttwochars isEqualToString:@"ける"] || [lasttwochars isEqualToString:@"げる"] || [lasttwochars isEqualToString:@"せる"] || [lasttwochars isEqualToString:@"ぜる"] || [lasttwochars isEqualToString:@"ねる"] || [lasttwochars isEqualToString:@"てる"] || [lasttwochars isEqualToString:@"でる"]) {
                type = @"eru";
            }
            else {
                type = @"u";
            }
        }
        else if ([lasttwochars isEqualToString:@"する"] || [lasttwochars isEqualToString:@"くる"] || [lasttwochars isEqualToString:@"来る"]) {
            type = @"irr";
        }
        else if ([verbending isEqualToString:@"く"]) {
            if ([word isEqualToString:@"いく"] || [word isEqualToString:@"行く"]) {
                type = @"iku";
            }
            else {
                type = @"u";
            }
        }
        else if ([verbending isEqualToString:@"な"] || [verbending isEqualToString:@"い"]) {
            if ([verbending isEqualToString:@"い"]) {
                type = @"i-adj";
            }
            else {
                type = @"na-adj";
            }
        }
        else {
            type = @"u";
        }
        return [self conjugateWord:word type:type];
    }
    else {
        return nil;
    }
    return nil;
}

- (NSDictionary *)conjugateWord:(NSString *)word type:(NSString *)type {
    NSString *lastchar = [word containsString:@"する"] || [word isEqualToString:@"くる"] || [word isEqualToString:@"来る"] ? [word substringFromIndex:word.length - 2] : [word substringFromIndex:word.length - 1];
    if ([lastchar isEqualToString:@"来る"]) {
        lastchar = @"くる";
    }
    NSArray *dataset;
    if ([type containsString:@"adj"]) {
        dataset = _conjugadjData;
    }
    else {
        dataset = _conjugverbData;
    }
    NSMutableDictionary *tmpdict = [NSMutableDictionary new];
    for (NSDictionary *d in dataset) {
        if ([type containsString:@"adj"]) {
            if ([lastchar isEqualToString:d[@"adj_dict_form"]] && [type isEqualToString:d[@"type"]]) {
                for (NSString *key in d.allKeys) {
                    if ([key isEqualToString:@"type"]) {
                        continue;
                    }
                    else {
                        tmpdict[key] = [NSString stringWithFormat:@"%@%@", [word substringToIndex:word.length-1], d[key]];
                    }
                }
                break;
            }
        }
        else if ([lastchar isEqualToString:d[@"dict_form"]] && [type isEqualToString:d[@"type"]]) {
            for (NSString *key in d.allKeys) {
                if ([key isEqualToString:@"type"]) {
                    continue;
                }
                if ([word isEqualToString:@"来る"]) {
                    tmpdict[key] = [NSString stringWithFormat:@"%@%@", [word substringToIndex:1], [(NSString *)d[key] substringFromIndex:1]];
                }
                else {
                    if ([type isEqualToString:@"irr"]) {
                        tmpdict[key] = [NSString stringWithFormat:@"%@%@", [word substringToIndex:word.length-2], d[key]];
                    }
                    else {
                        tmpdict[key] = [NSString stringWithFormat:@"%@%@", [word substringToIndex:word.length-1], d[key]];
                    }
                }
            }
            break;
        }
    }
    return @{@"data" : tmpdict, @"type" : type};
}
@end
