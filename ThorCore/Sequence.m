#import "Sequence.h"

@implementation NSArray (Sequence)

- (NSArray *)map:(id(^)(id))map {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count];
    
    for (id obj in self)
        [result addObject:map(obj)];
    
    return [result copy];
}

- (id)reduce:(id(^)(id, id))reduce seed:(id)seed {
    for (id obj in self)
        seed = reduce(seed, obj);
    
    return seed;
}

- (NSArray *)filter:(BOOL(^)(id))filter {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count / 2];
    
    for (id obj in self)
        if (filter(obj))
            [result addObject:obj];
    
    return [result copy];
}

- (BOOL)any:(BOOL(^)(id))predicate {
    for (id obj in self)
        if (predicate(obj))
            return YES;
    return NO;
}

- (BOOL)all:(BOOL(^)(id))predicate {
    for (id obj in self)
        if (!predicate(obj))
            return NO;
    return YES;
}

- (void)each:(void(^)(id))each {
    for (id obj in self)
        each(obj);
}

- (id)skip:(NSInteger)howMany {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count - howMany];
    
    for (NSInteger i = howMany; i < self.count; i++)
        [result addObject:[self objectAtIndex:i]];
    
    return result;
}

- (id)take:(NSInteger)howMany {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:howMany];
    
    for (int i = 0; i < howMany; i++)
        [result addObject:[self objectAtIndex:i]];
    
    return result;
}

- (NSArray *)skipWhile:(BOOL(^)(id))predicate {
    NSMutableArray *result = [NSMutableArray array];
    
    for (id obj in self) {
        if (predicate(obj))
            continue;
        
        [result addObject:obj];
    }
    
    return result;
}

- (NSArray *)takeWhile:(BOOL(^)(id))predicate {
    NSMutableArray *result = [NSMutableArray array];
    
    for (id obj in self) {
        if (!predicate(obj))
            break;
        
        [result addObject:obj];
    }
    
    return result;
}

- (NSArray *)concat:(NSArray *)other {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count + other.count];
    
    for (id obj in self)
        [result addObject:obj];
    
    for (id obj in other)
        [result addObject:obj];
    
    return result;
}

@end