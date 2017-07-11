# P4 Project - Copy the desired incoming packets to the CPU with runtime IP configuration

## Description
This program shows how we can mirror the incoming packets to the CPU port for desired IP addresses. 
The program acts as simple switch if no packets should be mirrored to the CPU.

The P4 program does the following:
- incoming packets are mirrored to the CPU port in the ingress pipeline if the source IP addresses are in the `copy_to_cpu` table. This table can be modified from the [commands](commands.txt). The current table contains 2 IP addresses: `10.0.1.0` and `10.0.3.0`;
- next hop is obtained from the ipv4_lpm table in the ingress pipeline;
- the packet's destination is obtained from the forward table in the ingress pipeline;
- the original packet is sent to it's original destination in the egress pipeline;

### Before running the program
You will need to clone 2 repositories and install their dependencies. 
To clonde the repositories:

- `git clone https://github.com/p4lang/behavioral-model.git bmv2`.
This repository is the behavioral model. It is a C++ software switch that will behave according to the P4 program. Since `bmv2` is a C++ repository it has more external dependencies. Click [here](https://github.com/p4lang/behavioral-model/blob/master/README.md) to see the dependencies of `bmv2`.

- `git clone https://github.com/p4lang/p4c-bm.git p4c-bmv2`
This repository is the compiler for the behavioral model. It takes P4 program and output a JSON file which can be loaded
by the behavioral model. Click [here](https://github.com/p4lang/p4c-bm/blob/master/README.rst) to see the dependencies of `p4c-bmv2`.

Do not forget to update the values of the shell variables BMV2_PATH and P4C_BM_PATH in the `env.sh` file - located in the root directory of this repository.

You will also need to run `sudo ./veth_setup.sh` command to setup the veth interfaces needed by the switch - located in the root directory of this repository.

### Scripts in the repository
This repository contains 4 scripts:
- [run_switch.sh](run_switch.sh): compiles the P4 program and starts the switch, 
  also configures the data plane by running the CLI [commands](commands.txt);
- [receive.py](receive.py): sniffes packets on port passed as argument and outputs them as a hexdump. Pass `veth0` as argument to sniff the CPU port;
- [send_one.py](send_one.py): sends 1 simple IPv4 packet on `port 4 (veth8 or veth9)`;
- [send_many.py](send_many.py): sends 4 simple IPv4 packets on `port 4 (veth8 or veth9)`;

If you take a look at [commands](commands.txt), you'll notice the following command: `mirroring_add 250 0`. This means that all the cloned packets with mirror id `250` will be sent to `port 0`, which is our de facto `CPU port`. This is the reason why [receive.py](receive.py) should sniff for incoming packets on `port 0(veth0 or veth1)`. 

If you want to change the `CPU port` edit the `mirroring_add` command in the [commands](commands.txt);.

#### To start a simple demo run the following scripts, each in a different console:
- `sudo ./run_switch.sh` - starts the switch and configure the tables and the mirroring session;
- `sudo python receive.py veth0` - starts the `CPU port listener`(which is `port 0(veth0 or veth1)` in our case);
- `sudo python send_one.py` - sends one packet on `port 4(veth8 or veth9)`; 

Every time you send a packet, it should be displayed by the `CPU port` listener, since the sent packet has the following default attributes: destination IP `10.0.0.1` and destination MAC `00:00:00:00:00:01` and the destination IP is saved in the `copy_to_cpu` table inside the [commands](commands.txt).

If you want you can write the source IP addresses of the sniffed packets to a `log file`. To do this edit the [receive.py](receive.py) file. See the lines between 30-34.

Notice that if you pass `veth2` or `veth8` to the `CPU port listener` you will be able to sniff the same packet on these ports, because the host which has IP `10.0.0.1` and MAC `00:00:00:00:00:01` is connected to `port 1(veth2 or veth3)` (see the [commands](commands.txt)) and the sender is sending the packet from `port 4(veth8 or veth9)`.

#### To start a complex demo run the following scripts, each in a different console:
- `sudo ./run_switch.sh` - starts the switch and configure the tables and the mirroring session;
- `sudo python receive.py veth0` - starts the `CPU port listener`(which is `port 0(veth0-1)` in our case);
- `sudo python receive.py veth2` - starts the host1(MAC:00:00:00:00:00:01 IP:10.0.0.1) listener on `port 1(veth2)`
- `sudo python receive.py veth4` - starts the host2(MAC:00:00:00:00:00:02 IP:10.0.0.2) listener on `port 2(veth4)`
- `sudo python send_many.py` - sends 4 packets on `port 4(veth8)`;

Observe the hexdump output of the listeners and [send_many.py](send_many.py) code to see the source/destination mac/ip addresses for these 4 packets in more detail. Packets P1 and P3 must be mirrored to the CPU port since these packets' source ip addresses are in the `copy_to_cpu` table.

Feel free to send me a mail(see my profile), if you did not understand something. Thats all. :)
