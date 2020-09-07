# Moloch Contract Extensions

Any crazy ideas. these are not audited or even tested.

## Minions

Minions runs arbitrary contract code after being approved by a dao proposal

### The Minion

file: minion/Minion.sol 

description: standard minion contract

contributors: @wolflo @dekanbro

### Daedalus

file: minion/Daedalus.sol 

description: Minion type contract setup as a sub dao of a parent dao. Takes and extra an extra argument in the contractor to set parent dao and exposes a function to do withdraws from it. This is mainly a UX thing so withdraws do not require another proposal and go directly to the dao bank.

contributors: @dekanbro

### Icarus

file: minion/Icarus.sol 

description: Minion type contract setup to execute early when some quorum of yes votes is met.

contributors: @dekanbro

## Vaults

Vaults are proposal helpers that have some token balance that can be offered through tribute

### Transmutation

file: vaults/Transmutation.sol 

description: transfer some token ant some exchange rate to the dao when payment is requested of depositToken

contributors: @dekanbro

### Transvolution

file: vaults/Transvolution.sol 

description: 

contributors: 

### Transmigration

file: TBD

description: 

contributors: 

## Metempsychosis

Other totally random stuff

Bone them young so they metempsychosis. That we live after death. Our souls. That a man’s soul after he dies. Dignam’s soul...

### Navidson

file: other/Navidson.sol

description: An airdrop type contract for moloch members. Based on the lexdao dripdrop contract, modified so moloch handles membership.

contributors: 

### Whalestoe

file: other/Whalestoe.sol

description: a readonly token wrapper around moloch shares. This allows Metamask or other wallets looking for balanceOf to see the shares.

contributors: 

## Minator

file: TBD

description: Thoughts scatter at a monent's notice like birds startled by a shot

contributors: 
