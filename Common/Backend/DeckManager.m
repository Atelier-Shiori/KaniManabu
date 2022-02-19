//
//  DeckManager.m
//  WaniManabu
//
//  Created by 丈槍由紀 on 1/10/22.
//

#import "DeckManager.h"
#import "SRScheduler.h"

@implementation DeckManager
+ (instancetype)sharedInstance {
    static DeckManager *sharedManager = nil;
    static dispatch_once_t deckManagertoken;
    dispatch_once(&deckManagertoken, ^{
        sharedManager = [DeckManager new];
    });
    return sharedManager;
}

- (bool)createDeck:(NSString *)deckname withType:(int)type {
    if (![self checkDeckExists:deckname withType:type]) {
        NSManagedObject *newDeck = [NSEntityDescription insertNewObjectForEntityForName:@"Decks" inManagedObjectContext:_moc];
        [newDeck setValue:deckname forKey:@"deckName"];
        [newDeck setValue:@(type) forKey:@"deckType"];
        [newDeck setValue:NSUUID.UUID forKey:@"deckUUID"];
        [newDeck setValue:@(NSDate.date.timeIntervalSince1970) forKey:@"nextLearnInterval"];
        [_moc performBlockAndWait:^{
                [_moc save:nil];
        }];
        return true;
    }
    return false;
}

- (bool)checkDeckExists:(NSString *)deckname withType:(int)type {
    @try { [_moc setQueryGenerationFromToken:NSQueryGenerationToken.currentQueryGenerationToken error:nil];} @catch (NSException *ex) {}
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    fetchRequest.entity = [NSEntityDescription entityForName:@"Decks" inManagedObjectContext:_moc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"deckName == %@ AND deckType == %i",deckname, type];
    fetchRequest.predicate = predicate;
    NSError *error = nil;
    return [_moc executeFetchRequest:fetchRequest error:&error].count > 0;
}

- (bool)checkDeckUUIDExists:(NSUUID *)uuid {
    @try { [_moc setQueryGenerationFromToken:NSQueryGenerationToken.currentQueryGenerationToken error:nil];} @catch (NSException *ex) {}
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    fetchRequest.entity = [NSEntityDescription entityForName:@"Decks" inManagedObjectContext:_moc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"deckUUID == %@",uuid];
    fetchRequest.predicate = predicate;
    NSError *error = nil;
    return [_moc executeFetchRequest:fetchRequest error:&error].count > 0;
}

- (bool)deleteDeckWithDeckUUID: (NSUUID *)uuid {
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    fetchRequest.entity = [NSEntityDescription entityForName:@"Decks" inManagedObjectContext:_moc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"deckUUID == %@",uuid];
    fetchRequest.predicate = predicate;
    NSError *error = nil;
    NSArray *decks = [_moc executeFetchRequest:fetchRequest error:&error];
    if (decks.count > 0) {
        NSManagedObject *deck = decks[0];
        [_moc deleteObject:deck];
        [_moc performBlockAndWait:^{
            [_moc save:nil];
        }];
        return true;
    }
    return false;
}

- (NSArray *)retrieveDecks {
    @try { [_moc setQueryGenerationFromToken:NSQueryGenerationToken.currentQueryGenerationToken error:nil];} @catch (NSException *ex) {}
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    fetchRequest.entity = [NSEntityDescription entityForName:@"Decks" inManagedObjectContext:_moc];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
                                        initWithKey:@"deckName" ascending:YES];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    __block NSError *error = nil;
    __block NSArray *decks;
    [_moc performBlockAndWait:^{
        decks = [_moc executeFetchRequest:fetchRequest error:&error];
    }];
    return decks;
}

- (NSManagedObject *)getDeckMetadataWithUUID:(NSUUID *)uuid {
    @try { [_moc setQueryGenerationFromToken:NSQueryGenerationToken.currentQueryGenerationToken error:nil];} @catch (NSException *ex) {}
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    fetchRequest.entity = [NSEntityDescription entityForName:@"Decks" inManagedObjectContext:_moc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"deckUUID == %@",uuid];
    fetchRequest.predicate = predicate;
    NSError *error = nil;
    NSArray *tmparray =  [_moc executeFetchRequest:fetchRequest error:&error];
    if (tmparray.count > 0) {
        return tmparray[0];
    }
    return nil;
}

- (NSUUID *)getDeckUUIDWithDeckName:(NSString *)deckname withDeckType:(DeckType)type {
    @try { [_moc setQueryGenerationFromToken:NSQueryGenerationToken.currentQueryGenerationToken error:nil];} @catch (NSException *ex) {}
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    fetchRequest.entity = [NSEntityDescription entityForName:@"Decks" inManagedObjectContext:_moc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"deckName == %@ AND deckType == %i",deckname,type];
    fetchRequest.predicate = predicate;
    NSError *error = nil;
    NSArray *tmparray =  [_moc executeFetchRequest:fetchRequest error:&error];
    if (tmparray.count > 0) {
        return [(NSManagedObject *)tmparray[0] valueForKey:@"deckUUID"];
    }
    return nil;
}

# pragma mark Review Queue Methods

- (NSArray *)retrieveReviewItemsForDeckUUID:(NSUUID *)uuid withType:(int)type {
    @try { [_moc setQueryGenerationFromToken:NSQueryGenerationToken.currentQueryGenerationToken error:nil];} @catch (NSException *ex) {}
    NSMutableArray *reviewqueue = [NSMutableArray new];
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    switch (type) {
        case DeckTypeKana:
            fetchRequest.entity = [NSEntityDescription entityForName:@"KanaCards" inManagedObjectContext:_moc];
            break;
        case DeckTypeKanji:
            fetchRequest.entity = [NSEntityDescription entityForName:@"KanjiCards" inManagedObjectContext:_moc];
            break;
        case DeckTypeVocab:
            fetchRequest.entity = [NSEntityDescription entityForName:@"VocabCards" inManagedObjectContext:_moc];
            break;
        default:
            return nil;
    }
    // Check for only learned cards, not suspended cards and not burned cards (SRS Stage 9)
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"deckUUID == %@ AND learned == %@ AND suspended == %@ AND srsstage < %i",uuid, @YES, @NO, 9];
    fetchRequest.predicate = predicate;
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
                                        initWithKey:@"nextreviewinterval" ascending:YES];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    NSError *error = nil;
    NSArray *cards = [_moc executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *card in cards) {
        if (((NSNumber *)[card valueForKey:@"inreview"]).boolValue) {
            // Card not fully reviewed, add to the review queue
            [reviewqueue addObject:card];
        }
        else {
            // Check date
            NSDate *nextReviewDate = [NSDate dateWithTimeIntervalSince1970:((NSNumber *)[card valueForKey:@"nextreviewinterval"]).doubleValue];
            if (nextReviewDate.timeIntervalSinceNow < 0) {
                // Card up for review, add to review queue.
                [reviewqueue addObject:card];
            }
        }
    }
    return reviewqueue;
}

- (NSArray *)retrieveAllReviewItems {
    @try { [_moc setQueryGenerationFromToken:NSQueryGenerationToken.currentQueryGenerationToken error:nil];} @catch (NSException *ex) {}
    NSMutableArray *reviewqueue = [NSMutableArray new];
    for (int type = 0; type < 3; type++) {
        NSFetchRequest *fetchRequest = [NSFetchRequest new];
        switch (type) {
            case DeckTypeKana:
                fetchRequest.entity = [NSEntityDescription entityForName:@"KanaCards" inManagedObjectContext:_moc];
                break;
            case DeckTypeKanji:
                fetchRequest.entity = [NSEntityDescription entityForName:@"KanjiCards" inManagedObjectContext:_moc];
                break;
            case DeckTypeVocab:
                fetchRequest.entity = [NSEntityDescription entityForName:@"VocabCards" inManagedObjectContext:_moc];
                break;
            default:
                return nil;
        }
        // Check for only learned cards, not suspended cards and not burned cards (SRS Stage 9)
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"learned == %@ AND suspended == %@ AND srsstage < %i",@YES, @NO, 9];
        fetchRequest.predicate = predicate;
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
                                            initWithKey:@"nextreviewinterval" ascending:YES];
        [fetchRequest setSortDescriptors:@[sortDescriptor]];
        __block NSError *error = nil;
        __block NSArray *cards;
        [_moc performBlockAndWait:^{
           cards = [_moc executeFetchRequest:fetchRequest error:&error];
        }];
        for (NSManagedObject *card in cards) {
            if (((NSNumber *)[card valueForKey:@"inreview"]).boolValue) {
                // Card not fully reviewed, add to the review queue
                [reviewqueue addObject:card];
            }
            else {
                // Check date
                NSDate *nextReviewDate = [NSDate dateWithTimeIntervalSince1970:((NSNumber *)[card valueForKey:@"nextreviewinterval"]).doubleValue];
                if (nextReviewDate.timeIntervalSinceNow < 0) {
                    // Card up for review, add to review queue.
                    [reviewqueue addObject:card];
                }
            }
        }
    }
    return reviewqueue;
}

- (long)getQueuedReviewItemsCountforUUID:(NSUUID *)uuid withType:(int)type {
    return [self retrieveReviewItemsForDeckUUID:uuid withType:type].count;
}

# pragma mark Learning Queue Methods
- (NSArray *)setandretrieveLearnItemsForDeckUUID:(NSUUID *)uuid withType:(int)type {
    return [self setandretrieveLearnItemsForDeckUUID:uuid withType:type learningmore:NO];
}
- (NSArray *)setandretrieveLearnItemsForDeckUUID:(NSUUID *)uuid withType:(int)type learningmore:(bool)learningmore {
    @try { [_moc setQueryGenerationFromToken:NSQueryGenerationToken.currentQueryGenerationToken error:nil];} @catch (NSException *ex) {}
    NSManagedObject *deckmeta = [self getDeckMetadataWithUUID:uuid];
    NSMutableArray *learnqueue = [NSMutableArray new];
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    NSFetchRequest *fetchRequestlearning = [NSFetchRequest new];
    switch (type) {
        case DeckTypeKana:
            fetchRequest.entity = [NSEntityDescription entityForName:@"KanaCards" inManagedObjectContext:_moc];
            break;
        case DeckTypeKanji:
            fetchRequest.entity = [NSEntityDescription entityForName:@"KanjiCards" inManagedObjectContext:_moc];
            break;
        case DeckTypeVocab:
            fetchRequest.entity = [NSEntityDescription entityForName:@"VocabCards" inManagedObjectContext:_moc];
            break;
        default:
            return nil;
    }
    fetchRequestlearning.entity = fetchRequest.entity;
    // Check for cards not learned yet, but not suspended ones
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"deckUUID == %@ AND learned == %@ AND suspended == %@" ,uuid, @NO, @NO];
    fetchRequestlearning.predicate = [NSPredicate predicateWithFormat:@"deckUUID == %@ AND learned == %@ AND learning == %@ AND suspended == %@" ,uuid, @NO, @YES, @NO];
    NSSortDescriptor *sortDescriptor;
    switch (((NSNumber *)[deckmeta valueForKey:@"newcardmode"]).intValue) {
        case OldCardsFirst:
        case NewCardsRandom:
        default:{
            sortDescriptor = [[NSSortDescriptor alloc]
                              initWithKey:@"datecreated" ascending:YES];
            break;
        }
        case NewCardsFirst: {
            sortDescriptor = [[NSSortDescriptor alloc]
                                                initWithKey:@"datecreated" ascending:NO];
            break;
        }
    }
    
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    // Add cards that the user is still learning
    __block NSError *error = nil;
    __block NSArray *learningcards;
    [_moc performBlockAndWait:^{
        learningcards = [_moc executeFetchRequest:fetchRequestlearning error:&error];
    }];
    [learnqueue addObjectsFromArray:learningcards];
    bool overridelimit = ((NSNumber *)[deckmeta valueForKey:@"overridenewcardlimit"]).boolValue;
    int maxlearnlimit = overridelimit ? ((NSNumber *)[deckmeta valueForKey:@"newcardlimit"]).intValue : ((NSNumber *)[NSUserDefaults.standardUserDefaults valueForKey:@"DeckNewCardLimitPerDay"]).intValue;
    if (((learnqueue.count <= maxlearnlimit && maxlearnlimit != 0) || maxlearnlimit == 0 )&& ([self getLearnDateForDeckUUID:uuid].timeIntervalSinceNow <= 0 || learningmore)) {
        NSArray *newcards = [_moc executeFetchRequest:fetchRequest error:&error];
        if (((NSNumber *)[deckmeta valueForKey:@"newcardmode"]).intValue == NewCardsRandom) {
            NSMutableArray *usedRandomNumbers = [NSMutableArray new];
            do {
                int ranindex = arc4random_uniform((int)newcards.count);
                for (NSNumber *usednum in usedRandomNumbers) {
                    if (usednum.intValue == ranindex) {
                        // Number used, generate another
                        continue;
                    }
                }
                [usedRandomNumbers addObject:@(ranindex)];
                NSManagedObject *card = newcards[ranindex];
                [card setValue:@YES forKey:@"learning"];
                [learnqueue addObject:card];
            }
            while (learnqueue.count < maxlearnlimit);
        }
        else {
            for (NSManagedObject *card in newcards) {
                [card setValue:@YES forKey:@"learning"];
                [learnqueue addObject:card];
                if (learnqueue.count >= maxlearnlimit) {
                    // Learn limit reached, stop adding cards
                    break;
                }
            }
        }
        if (!learningmore) {
            [self setLearnDateForDeckUUID:uuid setToday:NO];
        }
        [_moc performBlockAndWait:^{
            [_moc save:nil];
        }];
    }
    return learnqueue;
}

- (void)setLearnDateForDeckUUID:(NSUUID *)uuid setToday:(bool)today {
    @try { [_moc setQueryGenerationFromToken:NSQueryGenerationToken.currentQueryGenerationToken error:nil];} @catch (NSException *ex) {}
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    fetchRequest.entity = [NSEntityDescription entityForName:@"Decks" inManagedObjectContext:_moc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"deckUUID == %@",uuid];
    fetchRequest.predicate = predicate;
    __block NSError *error = nil;
    __block NSArray *decks;
    [_moc performBlockAndWait:^{
        decks = [_moc executeFetchRequest:fetchRequest error:&error];
    }];
    
    if (decks.count > 0) {
        NSManagedObject *deck = decks[0];
        [deck setValue:today ? @(0) :@([NSCalendar.currentCalendar startOfDayForDate:[NSDate.date dateByAddingTimeInterval:86400]].timeIntervalSince1970) forKey:@"nextLearnInterval"];
    }
}

- (NSDate *)getLearnDateForDeckUUID: (NSUUID *)uuid {
    @try { [_moc setQueryGenerationFromToken:NSQueryGenerationToken.currentQueryGenerationToken error:nil];} @catch (NSException *ex) {}
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    fetchRequest.entity = [NSEntityDescription entityForName:@"Decks" inManagedObjectContext:_moc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"deckUUID == %@",uuid];
    fetchRequest.predicate = predicate;
    NSError *error = nil;
    NSArray *decks = [_moc executeFetchRequest:fetchRequest error:&error];
    if (decks.count > 0) {
        NSManagedObject *deck = decks[0];
        return [NSDate dateWithTimeIntervalSince1970:((NSNumber *)[deck valueForKey:@"nextLearnInterval"]).doubleValue];
    }
    return nil;
}

- (long)getQueuedLearnItemsCountforUUID:(NSUUID *)uuid withType:(int)type {
    @try { [_moc setQueryGenerationFromToken:NSQueryGenerationToken.currentQueryGenerationToken error:nil];} @catch (NSException *ex) {}
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    NSFetchRequest *fetchRequestlearning = [NSFetchRequest new];
    switch (type) {
        case DeckTypeKana:
            fetchRequest.entity = [NSEntityDescription entityForName:@"KanaCards" inManagedObjectContext:_moc];
            break;
        case DeckTypeKanji:
            fetchRequest.entity = [NSEntityDescription entityForName:@"KanjiCards" inManagedObjectContext:_moc];
            break;
        case DeckTypeVocab:
            fetchRequest.entity = [NSEntityDescription entityForName:@"VocabCards" inManagedObjectContext:_moc];
            break;
        default:
            return 0;
    }
    fetchRequestlearning.entity = fetchRequest.entity;
    // Check for cards not learned yet, but not suspended ones
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"deckUUID == %@ AND learned == %@ AND learning == %@ AND suspended == %@" ,uuid, @NO, @YES , @NO];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
                                        initWithKey:@"datecreated" ascending:YES];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    // Add cards that the user is still learning
    __block NSError *error = nil;
    __block long count = 0;
    [_moc performBlockAndWait:^{
        count = [_moc executeFetchRequest:fetchRequest error:&error].count;
    }];
    return count;
}

- (long)getNotLearnedItemCountForUUID:(NSUUID *)uuid withType:(int)type {
    @try { [_moc setQueryGenerationFromToken:NSQueryGenerationToken.currentQueryGenerationToken error:nil];} @catch (NSException *ex) {}
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    NSFetchRequest *fetchRequestlearning = [NSFetchRequest new];
    switch (type) {
        case DeckTypeKana:
            fetchRequest.entity = [NSEntityDescription entityForName:@"KanaCards" inManagedObjectContext:_moc];
            break;
        case DeckTypeKanji:
            fetchRequest.entity = [NSEntityDescription entityForName:@"KanjiCards" inManagedObjectContext:_moc];
            break;
        case DeckTypeVocab:
            fetchRequest.entity = [NSEntityDescription entityForName:@"VocabCards" inManagedObjectContext:_moc];
            break;
        default:
            return 0;
    }
    fetchRequestlearning.entity = fetchRequest.entity;
    // Check for cards not learned yet, but not suspended ones
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"deckUUID == %@ AND learned == %@ AND suspended == %@" ,uuid, @NO, @NO];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
                                        initWithKey:@"datecreated" ascending:YES];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    // Add cards that the user is still learning
    NSError *error = nil;
    return [_moc executeFetchRequest:fetchRequest error:&error].count;
}

- (NSArray *)getAllLearnItems {
    @try { [_moc setQueryGenerationFromToken:NSQueryGenerationToken.currentQueryGenerationToken error:nil];} @catch (NSException *ex) {}
    NSMutableArray *tmparray = [NSMutableArray new];
    for (int type = 0; type < 3; type++) {
        NSFetchRequest *fetchRequest = [NSFetchRequest new];
        NSFetchRequest *fetchRequestlearning = [NSFetchRequest new];
        switch (type) {
            case DeckTypeKana:
                fetchRequest.entity = [NSEntityDescription entityForName:@"KanaCards" inManagedObjectContext:_moc];
                break;
            case DeckTypeKanji:
                fetchRequest.entity = [NSEntityDescription entityForName:@"KanjiCards" inManagedObjectContext:_moc];
                break;
            case DeckTypeVocab:
                fetchRequest.entity = [NSEntityDescription entityForName:@"VocabCards" inManagedObjectContext:_moc];
                break;
            default:
                break;
        }
        fetchRequestlearning.entity = fetchRequest.entity;
        // Check for cards not learned yet, but not suspended ones
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"learned == %@ AND learning == %@ AND suspended == %@" , @NO, @YES , @NO];
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
                                            initWithKey:@"datecreated" ascending:YES];
        [fetchRequest setSortDescriptors:@[sortDescriptor]];
        // Add cards that the user is still learning
        NSError *error = nil;
        [tmparray addObjectsFromArray:[_moc executeFetchRequest:fetchRequest error:&error]];
    }
    return tmparray;
}

#pragma mark Card retrieval
- (NSArray *)retrieveCardsForDeckUUID:(NSUUID *)uuid withType:(int)type {
    @try { [_moc setQueryGenerationFromToken:NSQueryGenerationToken.currentQueryGenerationToken error:nil];} @catch (NSException *ex) {}
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    switch (type) {
        case DeckTypeKana:
            fetchRequest.entity = [NSEntityDescription entityForName:@"KanaCards" inManagedObjectContext:_moc];
            break;
        case DeckTypeKanji:
            fetchRequest.entity = [NSEntityDescription entityForName:@"KanjiCards" inManagedObjectContext:_moc];
            break;
        case DeckTypeVocab:
            fetchRequest.entity = [NSEntityDescription entityForName:@"VocabCards" inManagedObjectContext:_moc];
            break;
        default:
            return nil;
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"deckUUID == %@", uuid];
    fetchRequest.predicate = predicate;
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
                                        initWithKey:@"datecreated" ascending:YES];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    NSError *error = nil;
    NSArray *cards = [_moc executeFetchRequest:fetchRequest error:&error];
    NSMutableArray *tmpcardslist = [NSMutableArray new];
    for (NSManagedObject *obj in cards) {
        NSArray *keys = obj.entity.attributesByName.allKeys;
        NSMutableDictionary *tmpdict = [NSMutableDictionary dictionaryWithDictionary:[obj dictionaryWithValuesForKeys:keys]];
        tmpdict[@"managedObject"] = obj;
        tmpdict[@"cardtype"] = @(type);
        [tmpcardslist addObject:tmpdict];
    }
    return tmpcardslist;
}

- (NSArray *)retrieveAllCardswithPredicate:(NSPredicate *)predicates {
    @try { [_moc setQueryGenerationFromToken:NSQueryGenerationToken.currentQueryGenerationToken error:nil];} @catch (NSException *ex) {}
    NSMutableArray *tmpcardslist = [NSMutableArray new];
    for (int type = 0; type < 3; type++) {
        NSFetchRequest *fetchRequest = [NSFetchRequest new];
        switch (type) {
            case DeckTypeKana:
                fetchRequest.entity = [NSEntityDescription entityForName:@"KanaCards" inManagedObjectContext:_moc];
                break;
            case DeckTypeKanji:
                fetchRequest.entity = [NSEntityDescription entityForName:@"KanjiCards" inManagedObjectContext:_moc];
                break;
            case DeckTypeVocab:
                fetchRequest.entity = [NSEntityDescription entityForName:@"VocabCards" inManagedObjectContext:_moc];
                break;
            default:
                return nil;
        }
        NSPredicate *predicate;
        if (predicates) {
            predicate = predicates;
            fetchRequest.predicate = predicate;
        }
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
                                            initWithKey:@"datecreated" ascending:YES];
        [fetchRequest setSortDescriptors:@[sortDescriptor]];
        __block NSError *error = nil;
        __block NSArray *cards;
        [_moc performBlockAndWait:^{
            cards = [self.moc executeFetchRequest:fetchRequest error:&error];
        }];
        for (NSManagedObject *obj in cards) {
            NSArray *keys = obj.entity.attributesByName.allKeys;
            NSMutableDictionary *tmpdict = [NSMutableDictionary dictionaryWithDictionary:[obj dictionaryWithValuesForKeys:keys]];
            tmpdict[@"managedObject"] = obj;
            tmpdict[@"cardtype"] = @(type);
            [tmpcardslist addObject:tmpdict];
        }
    }
    return tmpcardslist;
}

- (NSArray *)retrieveAllCriticalCards {
    NSArray *tmparray = [self retrieveAllCardswithPredicate:[NSPredicate predicateWithFormat:@"learned == %@", @YES]];
    NSMutableArray *criticalitems = [NSMutableArray new];
    for (NSDictionary *card in tmparray) {
        int numbercorrect = ((NSNumber *)card[@"numansweredcorrect"]).intValue;
        int numberincorrect = ((NSNumber *)card[@"numansweredincorrect"]).intValue;
        double score = ((double)numbercorrect/((double)numbercorrect + (double)numberincorrect));
        if (score <= .7) {
            [criticalitems addObject:card];
        }
    }
    return criticalitems;
}

#pragma mark Card Management

- (bool)addCardWithDeckUUID:(NSUUID *)uuid withCardData:(NSDictionary *)cardData withType:(DeckType)type {
    if (cardData[@"japanese"]) {
        if ([self checkCardExistsInDeckWithDeckUUID:uuid withJapaneseWord:cardData[@"japanese"] withType:type]) {
            return false;
        }
        NSString *entity = @"";
        switch (type) {
            case DeckTypeKana:
                entity = @"KanaCards";
                break;
            case DeckTypeKanji:
                entity = @"KanjiCards";
                break;
            case DeckTypeVocab:
                entity = @"VocabCards";
                break;
            default:
                return false;
        }
        NSManagedObject *newCard = [NSEntityDescription insertNewObjectForEntityForName:entity inManagedObjectContext:_moc];
        for (NSString *key in cardData.allKeys) {
            [newCard setValue:cardData[key] forKey:key];
        }
        [newCard setValue:NSUUID.UUID forKey:@"carduuid"];
        [newCard setValue:uuid forKey:@"deckUUID"];
        [newCard setValue:@(NSDate.date.timeIntervalSince1970) forKey:@"datecreated"];
        // Only save card when the add card operation is from the editor, not an import to prevent notifications from triggering multiple times.
        [_moc performBlockAndWait:^{
            [_moc save:nil];
        }];
        return true;
    }
    return false;
}

- (bool)modifyCardWithCardUUID:(NSUUID *)uuid withCardData:(NSDictionary *)cardData withType:(DeckType)type {
    NSDictionary *card = [self getCardWithCardUUID:uuid withType:type];
    if (card) {
        NSManagedObject *obj = card[@"managedObject"];
        for (NSString *key in cardData.allKeys) {
            [obj setValue:cardData[key] forKey:key];
        }
                [_moc performBlockAndWait:^{
            [_moc save:nil];
        }];
        return true;
    }
    return false;
}

- (bool)checkCardExistsInDeckWithDeckUUID:(NSUUID *)uuid withJapaneseWord:(NSString *)word withType:(DeckType)type {
    @try { [_moc setQueryGenerationFromToken:NSQueryGenerationToken.currentQueryGenerationToken error:nil];} @catch (NSException *ex) {}
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    switch (type) {
        case DeckTypeKana:
            fetchRequest.entity = [NSEntityDescription entityForName:@"KanaCards" inManagedObjectContext:_moc];
            break;
        case DeckTypeKanji:
            fetchRequest.entity = [NSEntityDescription entityForName:@"KanjiCards" inManagedObjectContext:_moc];
            break;
        case DeckTypeVocab:
            fetchRequest.entity = [NSEntityDescription entityForName:@"VocabCards" inManagedObjectContext:_moc];
            break;
        default:
            return false;
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"deckUUID == %@ AND japanese ==[c] %@", uuid, word];
    fetchRequest.predicate = predicate;
    NSError *error = nil;
    return [_moc executeFetchRequest:fetchRequest error:&error].count > 0;
}

- (NSDictionary *)getCardWithCardUUID:(NSUUID *)uuid withType:(DeckType)type {
    @try { [_moc setQueryGenerationFromToken:NSQueryGenerationToken.currentQueryGenerationToken error:nil];} @catch (NSException *ex) {}
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    switch (type) {
        case DeckTypeKana:
            fetchRequest.entity = [NSEntityDescription entityForName:@"KanaCards" inManagedObjectContext:_moc];
            break;
        case DeckTypeKanji:
            fetchRequest.entity = [NSEntityDescription entityForName:@"KanjiCards" inManagedObjectContext:_moc];
            break;
        case DeckTypeVocab:
            fetchRequest.entity = [NSEntityDescription entityForName:@"VocabCards" inManagedObjectContext:_moc];
            break;
        default:
            return false;
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"carduuid == %@", uuid];
    fetchRequest.predicate = predicate;
    NSError *error = nil;
    NSArray *tmparray = [_moc executeFetchRequest:fetchRequest error:&error];
    if (tmparray.count > 0) {
        NSManagedObject *obj = tmparray[0];
        NSArray *keys = obj.entity.attributesByName.allKeys;
        NSMutableDictionary *tmpdict = [NSMutableDictionary dictionaryWithDictionary:[obj dictionaryWithValuesForKeys:keys]];
        tmpdict[@"managedObject"] = obj;
        tmpdict[@"cardtype"] = @(type);
        return tmpdict;
    }
    return nil;
}

- (void)resetCardWithCardUUID:(NSUUID *)uuid withType:(DeckType)type {
    @try { [_moc setQueryGenerationFromToken:NSQueryGenerationToken.currentQueryGenerationToken error:nil];} @catch (NSException *ex) {}
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    switch (type) {
        case DeckTypeKana:
            fetchRequest.entity = [NSEntityDescription entityForName:@"KanaCards" inManagedObjectContext:_moc];
            break;
        case DeckTypeKanji:
            fetchRequest.entity = [NSEntityDescription entityForName:@"KanjiCards" inManagedObjectContext:_moc];
            break;
        case DeckTypeVocab:
            fetchRequest.entity = [NSEntityDescription entityForName:@"VocabCards" inManagedObjectContext:_moc];
            break;
        default:
            return;
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"carduuid == %@", uuid];
    fetchRequest.predicate = predicate;
    NSError *error = nil;
    NSArray *tmparray = [_moc executeFetchRequest:fetchRequest error:&error];
    if (tmparray.count > 0) {
        NSManagedObject *obj = tmparray[0];
        [obj setValue:@(0) forKey:@"numansweredcorrect"];
        [obj setValue:@(0) forKey:@"numansweredincorrect"];
        [obj setValue:@NO forKey:@"reviewedmeaning"];
        [obj setValue:@NO forKey:@"reviewedreading"];
        [obj setValue:@(0) forKey:@"reviewincorrectcount"];
        [obj setValue:@(0) forKey:@"reviewincorrectmeaning"];
        [obj setValue:@(0) forKey:@"srsstage"];
        [obj setValue:@(0) forKey:@"proposedsrsstage"];
        [obj setValue:@NO forKey:@"learned"];
        [obj setValue:@NO forKey:@"learning"];
        [obj setValue:@NO forKey:@"inreview"];
        [obj setValue:@(0) forKey:@"lastreviewed"];
        [obj setValue:@(0) forKey:@"nextreviewinterval"];
                [_moc performBlockAndWait:^{
            [_moc save:nil];
        }];
    }
}

- (void)resetCardToEnlightenedWithCardUUID:(NSUUID *)uuid withType:(DeckType)type {
    @try { [_moc setQueryGenerationFromToken:NSQueryGenerationToken.currentQueryGenerationToken error:nil];} @catch (NSException *ex) {}
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    switch (type) {
        case DeckTypeKana:
            fetchRequest.entity = [NSEntityDescription entityForName:@"KanaCards" inManagedObjectContext:_moc];
            break;
        case DeckTypeKanji:
            fetchRequest.entity = [NSEntityDescription entityForName:@"KanjiCards" inManagedObjectContext:_moc];
            break;
        case DeckTypeVocab:
            fetchRequest.entity = [NSEntityDescription entityForName:@"VocabCards" inManagedObjectContext:_moc];
            break;
        default:
            return;
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"carduuid == %@", uuid];
    fetchRequest.predicate = predicate;
    NSError *error = nil;
    NSArray *tmparray = [_moc executeFetchRequest:fetchRequest error:&error];
    if (tmparray.count > 0) {
        NSManagedObject *obj = tmparray[0];
        [obj setValue:@(8) forKey:@"srsstage"];
        [_moc performBlockAndWait:^{
            [_moc save:nil];
        }];
    }
}

- (bool)deleteCardWithCardUUID:(NSUUID *)uuid withType:(DeckType)type {
    @try { [_moc setQueryGenerationFromToken:NSQueryGenerationToken.currentQueryGenerationToken error:nil];} @catch (NSException *ex) {}
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    switch (type) {
        case DeckTypeKana:
            fetchRequest.entity = [NSEntityDescription entityForName:@"KanaCards" inManagedObjectContext:_moc];
            break;
        case DeckTypeKanji:
            fetchRequest.entity = [NSEntityDescription entityForName:@"KanjiCards" inManagedObjectContext:_moc];
            break;
        case DeckTypeVocab:
            fetchRequest.entity = [NSEntityDescription entityForName:@"VocabCards" inManagedObjectContext:_moc];
            break;
        default:
            return false;
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"carduuid == %@", uuid];
    fetchRequest.predicate = predicate;
    NSError *error = nil;
    NSArray *tmparray = [_moc executeFetchRequest:fetchRequest error:&error];
    if (tmparray.count > 0) {
        NSManagedObject *obj = tmparray[0];
        [_moc deleteObject:obj];
                [_moc performBlockAndWait:^{
            [_moc save:nil];
        }];
        return true;
    }
    return false;
}

- (void)deleteAllCardsForDeckUUID:(NSUUID *)uuid withType:(int)type {
    @try { [_moc setQueryGenerationFromToken:NSQueryGenerationToken.currentQueryGenerationToken error:nil];} @catch (NSException *ex) {}
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    switch (type) {
        case DeckTypeKana:
            fetchRequest.entity = [NSEntityDescription entityForName:@"KanaCards" inManagedObjectContext:_moc];
            break;
        case DeckTypeKanji:
            fetchRequest.entity = [NSEntityDescription entityForName:@"KanjiCards" inManagedObjectContext:_moc];
            break;
        case DeckTypeVocab:
            fetchRequest.entity = [NSEntityDescription entityForName:@"VocabCards" inManagedObjectContext:_moc];
            break;
        default:
            return;
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"deckUUID == %@", uuid];
    fetchRequest.predicate = predicate;
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
                                        initWithKey:@"datecreated" ascending:YES];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    NSError *error = nil;
    NSArray *cards = [_moc executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *obj in cards) {
        [_moc deleteObject:obj];
    }
    [_moc performBlockAndWait:^{
            [_moc save:nil];
    }];
}

- (void)togglesuspendCardForCardUUID:(NSUUID *)uuid withType:(int)type {
    @try { [_moc setQueryGenerationFromToken:NSQueryGenerationToken.currentQueryGenerationToken error:nil];} @catch (NSException *ex) {}
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    switch (type) {
        case DeckTypeKana:
            fetchRequest.entity = [NSEntityDescription entityForName:@"KanaCards" inManagedObjectContext:_moc];
            break;
        case DeckTypeKanji:
            fetchRequest.entity = [NSEntityDescription entityForName:@"KanjiCards" inManagedObjectContext:_moc];
            break;
        case DeckTypeVocab:
            fetchRequest.entity = [NSEntityDescription entityForName:@"VocabCards" inManagedObjectContext:_moc];
            break;
        default:
            return;
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"carduuid == %@", uuid];
    fetchRequest.predicate = predicate;
    NSError *error = nil;
    NSArray *tmparray = [_moc executeFetchRequest:fetchRequest error:&error];
    if (tmparray.count > 0) {
        NSManagedObject *obj = tmparray[0];
        bool suspended = ((NSNumber *)[obj valueForKey:@"suspended"]).boolValue;
        [obj setValue:@(!suspended) forKey:@"suspended"];
                [_moc performBlockAndWait:^{
            [_moc save:nil];
        }];
    }
}

- (void)removeOrphanedCards {
    _importing = true;
    NSArray *tmpcards = [self retrieveAllCardswithPredicate:nil];
    for (NSDictionary *card in tmpcards) {
        NSManagedObject *obj = card[@"managedObject"];
        bool deckexists = [self checkDeckUUIDExists:card[@"deckUUID"]];
        if (!deckexists) {
            [_moc deleteObject:obj];
            [_moc performBlockAndWait:^{
                [_moc save:nil];
            }];
        }
    }
    _importing = false;
    [_moc performBlockAndWait:^{
        [_moc save:nil];
    }];
}
@end
