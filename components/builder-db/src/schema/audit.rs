table! {
    use crate::models::channel::{PackageChannelOperationMapping, PackageChannelTriggerMapping};
    use diesel::sql_types::{BigInt, Text, Nullable, Timestamptz};
    audit_package (origin, package_ident, channel) {
        package_ident -> Text,
        channel -> Text,
        operation -> PackageChannelOperationMapping,
        trigger -> PackageChannelTriggerMapping,
        requester_id -> BigInt,
        requester_name -> Text,
        created_at -> Nullable<Timestamptz>,
        origin -> Text,
    }
}

table! {
    use crate::models::channel::{PackageChannelOperationMapping, PackageChannelTriggerMapping};
    use diesel::sql_types::{BigInt, Array, Text, Nullable, Timestamptz};
    audit_package_group (origin, channel) {
        channel -> Text,
        package_ids -> Array<BigInt>,
        operation -> PackageChannelOperationMapping,
        trigger -> PackageChannelTriggerMapping,
        requester_id -> BigInt,
        requester_name -> Text,
        group_id -> BigInt,
        created_at -> Nullable<Timestamptz>,
        origin -> Text,
    }
}
