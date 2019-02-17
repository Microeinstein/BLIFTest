# bliftest.sh
This script allows to build and execute simulation tests for SIS `.blif` circuits.


### Command line usage:
  |Mode|Arguments|Description|
  |:-|:-|:-|
  | Fast test | `<circuit.blif> <tests>` | write, check, done |
  | Build | `-b <full.simtest> <tests>` | in case of high number of tests |
  | Execute | `<fsmd.blif> <full.simtest>[,tests]` | do not wait tests parsing |
  | Help | `-h` | _self explanatory_ |


  | Test parameters  | _(spaces are allowed everywhere)_ |
  |:-|:-|
  | `in` | Input bits |
  | `[=out]` | Expected output bits | if `*` prints the output without test |
  | `[=name]` | Name of the test |
  | `[,in...]` | Append another simulation |


### Examples:
```
./bliftest.sh  or4.blif  0101
./bliftest.sh  or4.blif  0101=1
./bliftest.sh  or4.blif  0101 = 1
./bliftest.sh  or4.blif  0 1 0 1 = 1

./bliftest.sh  mux4.blif 1 1010 1111 = 1111

./bliftest.sh  -b full.simtest  1100, 0110=1 000, 0001=*=Result
./bliftest.sh  fsm.blif  full.simtest
./bliftest.sh  fsm.blif  full.simtest,0011=0010=such cool very wow
```

---
## buildtest2019.sh
This other script launches `./bliftest.sh` with the necessary tests for the SIS project,
given by the *University of Verona* to first-year students graduating in IT.

It offers the opportunity to choose some options to adapt the tests to any design choices of the project.

Sample _asking-for-choices_ output:
```
La macchina controlla con uno stato in più...
  ...l'errore di EM=0   [y/N]?
  ...l'errore di SCARTO [y/N]?
  ...l'overflow di NB   [y/N]?
  ...l'overflow di NE   [y/N]?
```
Usage: 
```
./buildtest2019.sh
./bliftest.sh FSMD_final.blif test2019.simtest
```

---
#### test2019.simtest
Pregenerated tests with no additional FSM states in error checking.

---
## AIO copy-paste command list
Make sure that:
 * you're inside your project directory (`cd ~/Elaborato`)
 * your project file name is `FSMD_final.blif`

[old link]: # "
a=66bd028a88533cef61bd8b8528664863
b=3f591ff7fcb90e27b0bc3a05c6679f0c3c002843
wget https://gist.github.com/Microeinstein/${a}/archive/${b}.zip
"
```
a=BLIFTest
b=master
wget https://github.com/Microeinstein/${a}/archive/${b}.zip
fld=${a}-${b}
unzip ${fld}.zip
mv ${fld}/* .
rm ${fld}.zip ${fld}
chmod +x *.sh
./buildtest2019.sh
./bliftest.sh FSMD_final.blif test2019.simtest

```

#### Animated GIF of the execution:
![Here it should show the GIF...](https://github.com/Microeinstein/BLIFTest/raw/master/execution.gif)