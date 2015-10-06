module.exports.isSamePerson = (contact1, contact2) ->
    similar = contact1.datapoints.some (field) ->
        if field.name in ['tel', 'adr', 'email', 'chat']
            return hasField field, contact2
        else
            return false
    return contact1.fn is contact2.fn and similar

# Check if (cozy)contact fuzzily has the specified field
hasField = (field, contact, checkType = false) ->
    return false unless field.value?

    contact.datapoints.some (baseField) ->
        if field.name is baseField.name and
           (not checkType or checkType and field.type is baseField.type) and
           baseField.value?

            if field.name is 'tel'
                return field.value.replace(/[-\s]/g, '') is
                  baseField.value.replace(/[-\s]/g, '')

            else if field.name is 'adr'
                same = true
                i = 0
                while same and i < 7
                    same = same and field.value[i] is baseField.value[i] or
                    field.value[i] is "" and not baseField.value[i]? or
                    not field.value?[i] and baseField.value[i] is ""
                    i++

                return same

            else
                return field.value is baseField.value

        else
            return false


# Merge toMerge cozy contact in cozy's baseContact.
module.exports.mergeContacts = (base, toMerge) ->
    toMerge.datapoints.forEach (field) ->
        unless hasField field, base, true
            base.datapoints.push field

    delete toMerge.datapoints

    base.tags = _union base.tags, toMerge.tags
    delete toMerge.tags
    base = _extend base, toMerge
    return base

_union = (a, b) ->
    a = a or []
    b = b or []
    return a.concat b.filter (item) -> return a.indexOf(item) < 0

_extend = (a, b) ->
    for k, v of b
        if v?
            a[k] = v
    return a

