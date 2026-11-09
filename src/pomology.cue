
package pomology

import "list"

#Repository: string & =~"^[a-zA-Z0-9._-]{1,100}$"
#Codename:   string & =~"^[a-z]{1,12}$"

#Pomology: {
	varieties:     [#Codename, ...#Codename] & list.UniqueItems
	aspectOptions: [#Codename, ...#Codename] & list.UniqueItems
	cordons: [#Repository]: {
		tier: null | #Repository
		leaves: [#Repository]: {
			options: close({
				for variety in varieties {
					"\(variety)": or([for a in aspectOptions {a}])
				}
			})
		}
	}

	let rootNames = [for name, cordon in cordons if cordon.tier == null {name}]
	_exactOneRoot: len(rootNames) == 1

	_tiersPointToRoot: and([
		for _, cordon in cordons if cordon.tier != null {
			cordon.tier == rootNames[0]
		}
	])
}