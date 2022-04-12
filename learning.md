### Struct in solidity can be seen as Class in Python
### Mapping in solidty is like dictionary in python, it allows for look up






Create a multisig wallet that is based on key weight rather than numbers of approvals

Transaction on wallet can be of different type thats carries different weights
constructor must contain key weight for each user address
When sending transactions, we check with a modifier to be sure the address meet the required threshold of signature

CATEGORY OF TRANSACTION
1. Transfer(To other none Signer account) - 60
2. Deposit(Send funds to wallets) - 0
3. Withdrawals(To one of the signer wallet) - 80
4. Update Owners List 70


OVERRALL WEIGHT OF TRANSACTION
- 100
