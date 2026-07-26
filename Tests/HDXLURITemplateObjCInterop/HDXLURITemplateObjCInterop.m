@import HDXLURITemplate;

#import "HDXLURITemplateObjCInterop.h"

NSError * _Nullable
HDXLObjCDuplicateAssociationConstructionError(void) {
  NSError *error = nil;
  HDXLURIVariableValue *value = [
    [HDXLURIVariableValue alloc]
    initWithKeys:@[@"private-key-sentinel", @"private-key-sentinel"]
    values:@[@"private-first-value", @"private-second-value"]
    error:&error
  ];
  return value == nil ? error : nil;
}

NSError * _Nullable
HDXLObjCMismatchedAssociationConstructionError(void) {
  NSError *error = nil;
  HDXLURIVariableValue *value = [
    [HDXLURIVariableValue alloc]
    initWithKeys:@[@"key"]
    values:@[]
    error:&error
  ];
  return value == nil ? error : nil;
}

NSError * _Nullable
HDXLObjCReverseMismatchedAssociationConstructionError(void) {
  NSError *error = nil;
  HDXLURIVariableValue *value = [
    [HDXLURIVariableValue alloc]
    initWithKeys:@[]
    values:@[@"private-value"]
    error:&error
  ];
  return value == nil ? error : nil;
}

NSArray<NSString *> * _Nullable
HDXLObjCValidAssociationEnumeration(void) {
  NSError *error = nil;
  HDXLURIVariableValue *value = [
    [HDXLURIVariableValue alloc]
    initWithKeys:@[@"b", @"a"]
    values:@[@"2", @"1"]
    error:&error
  ];
  if (value == nil || error != nil) {
    return nil;
  }

  NSMutableArray<NSString *> *result = [NSMutableArray array];
  [value enumerateAssociationPairsUsingBlock:
    ^(NSString *key, NSString *pairValue, NSInteger index, BOOL *stop) {
      [result addObject:
        [NSString stringWithFormat:@"%@=%@:%ld", key, pairValue, index]
      ];
    }
  ];
  return result;
}

NSDictionary<NSString *, NSString *> * _Nullable
HDXLObjCValidAssociationDictionary(void) {
  NSError *error = nil;
  HDXLURIVariableValue *value = [
    [HDXLURIVariableValue alloc]
    initWithKeys:@[@"b", @"a"]
    values:@[@"2", @"1"]
    error:&error
  ];
  return value == nil || error != nil
    ? nil
    : value.associationValueAsDictionary;
}

BOOL
HDXLObjCAssociationEnumerationStopsEarly(void) {
  NSError *error = nil;
  HDXLURIVariableValue *value = [
    [HDXLURIVariableValue alloc]
    initWithKeys:@[@"a", @"b", @"c"]
    values:@[@"1", @"2", @"3"]
    error:&error
  ];
  if (value == nil || error != nil) {
    return NO;
  }

  __block NSInteger visitCount = 0;
  [value enumerateAssociationPairsUsingBlock:
    ^(NSString *key, NSString *pairValue, NSInteger index, BOOL *stop) {
      visitCount += 1;
      *stop = YES;
    }
  ];
  return visitCount == 1;
}

static BOOL
HDXLObjCAssociationSecureCodingRoundTripsValue(
  HDXLURIVariableValue *value
) {
  id copied = [value copy];
  if (copied != value || ![copied isEqual:value]) {
    return NO;
  }

  NSMutableArray<NSArray<id> *> *originalPairs = [NSMutableArray array];
  [value enumerateAssociationPairsUsingBlock:
    ^(NSString *key, NSString *pairValue, NSInteger index, BOOL *stop) {
      [originalPairs addObject:@[key, pairValue, @(index)]];
    }
  ];

  NSError *archiveError = nil;
  NSData *archive = [
    NSKeyedArchiver
    archivedDataWithRootObject:value
    requiringSecureCoding:YES
    error:&archiveError
  ];
  if (archive == nil || archiveError != nil) {
    return NO;
  }

  NSError *unarchiveError = nil;
  HDXLURIVariableValue *decoded = [
    NSKeyedUnarchiver
    unarchivedObjectOfClass:[HDXLURIVariableValue class]
    fromData:archive
    error:&unarchiveError
  ];
  if (
    decoded == nil
    || unarchiveError != nil
    || ![decoded isEqual:value]
    || ![decoded.associationValueAsDictionary
      isEqual:value.associationValueAsDictionary]
  ) {
    return NO;
  }

  NSMutableArray<NSArray<id> *> *decodedPairs = [NSMutableArray array];
  [decoded enumerateAssociationPairsUsingBlock:
    ^(NSString *key, NSString *pairValue, NSInteger index, BOOL *stop) {
      [decodedPairs addObject:@[key, pairValue, @(index)]];
    }
  ];
  return [decodedPairs isEqual:originalPairs];
}

BOOL
HDXLObjCAssociationSecureCodingRoundTrips(void) {
  NSError *constructionError = nil;
  HDXLURIVariableValue *ordered = [
    [HDXLURIVariableValue alloc]
    initWithKeys:@[@"b", @"a"]
    values:@[@"2", @"1"]
    error:&constructionError
  ];
  if (ordered == nil || constructionError != nil) {
    return NO;
  }

  HDXLURIVariableValue *customOrdered = [
    [HDXLURIVariableValue alloc]
    initWithDictionary:@{@"a": @"1", @"b": @"2", @"c": @"3"}
    sortDescriptor:^NSComparisonResult(NSString *lhs, NSString *rhs) {
      return [rhs compare:lhs];
    }
  ];

  NSArray<HDXLURIVariableValue *> *values = @[
    HDXLURIVariableValue.emptyAssociationVariableValue,
    [[HDXLURIVariableValue alloc] initWithKey:@"key" value:@"value"],
    ordered,
    customOrdered
  ];
  __block NSMutableArray<NSString *> *customOrder = [NSMutableArray array];
  [customOrdered enumerateAssociationPairsUsingBlock:
    ^(NSString *key, NSString *pairValue, NSInteger index, BOOL *stop) {
      [customOrder addObject:key];
    }
  ];
  if (![customOrder isEqual:@[@"c", @"b", @"a"]]) {
    return NO;
  }

  for (HDXLURIVariableValue *value in values) {
    if (!HDXLObjCAssociationSecureCodingRoundTripsValue(value)) {
      return NO;
    }
  }
  return YES;
}
