#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSError * _Nullable
HDXLObjCDuplicateAssociationConstructionError(void);

FOUNDATION_EXPORT NSError * _Nullable
HDXLObjCMismatchedAssociationConstructionError(void);

FOUNDATION_EXPORT NSError * _Nullable
HDXLObjCReverseMismatchedAssociationConstructionError(void);

FOUNDATION_EXPORT NSArray<NSString *> * _Nullable
HDXLObjCValidAssociationEnumeration(void);

FOUNDATION_EXPORT NSDictionary<NSString *, NSString *> * _Nullable
HDXLObjCValidAssociationDictionary(void);

FOUNDATION_EXPORT BOOL
HDXLObjCAssociationEnumerationStopsEarly(void);

FOUNDATION_EXPORT BOOL
HDXLObjCAssociationSecureCodingRoundTrips(void);

NS_ASSUME_NONNULL_END
