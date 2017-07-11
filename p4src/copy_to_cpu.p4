/* Copyright 2017-present Argela Technologies
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*************************************************************************
 ***********************  H E A D E R S **********************************
 *************************************************************************/
header_type cpu_header_t {
    fields {
        device: 8;
        reason: 8;
    }
}

header_type ethernet_t {
    fields {
        dstAddr     : 48;
        srcAddr     : 48;
        etherType   : 16;
    }
}

header_type ipv4_t {
    fields {
        version     : 4;
        ihl         : 4;
        diffserv    : 8;
        ipv4_length : 16;
        id          : 16;
        flags       : 3;
        offset      : 13;
        ttl         : 8;
        protocol    : 8;
        checksum    : 16;
        srcAddr     : 32;
        dstAddr     : 32;
    }
}

header_type tcp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        seqNo : 32;
        ackNo : 32;
        dataOffset : 4;
        res : 4;
        flags : 8;
        window : 16;
        checksum : 16;
        urgentPtr : 16;
    }
}

header_type current_ip_to_mirror {
    fields {
        ip : 32;
    }
}

header_type custom_metadata_t {
    fields {
        nhop_ipv4: 32;
    }
}

header_type intrinsic_metadata_t {
    fields {
        mcast_grp       : 4;
        egress_rid      : 4;
        mcast_hash      : 16;
        lf_field_list   : 32;
    }
}

header cpu_header_t cpu_header;
header ethernet_t ethernet;
header ipv4_t ipv4;
header tcp_t tcp;

metadata current_ip_to_mirror ip_mirror_meta;
metadata custom_metadata_t custom_metadata;
metadata intrinsic_metadata_t intrinsic_metadata;

/*************************************************************************
 ***********************  P A R S E R S **********************************
 *************************************************************************/

parser start {
    return select(current(0, 64)) {
        0 : parse_cpu_header;		// Go to parser parse_cpu_header
        default: parse_ethernet;	// Go to parser parse_ethernet
    }
}

parser parse_cpu_header {
    extract(cpu_header);
    return parse_ethernet;
}

#define ETHERTYPE_IPV4 0x0800

parser parse_ethernet {
    extract(ethernet);
    // Get the ethernet type value
	// and select which function to run
    return select(ethernet.etherType){
        ETHERTYPE_IPV4  : parse_ipv4; 	// Go to parser parse_ipv4
        default         : ingress; 		// Go to control ingress
    }
}

#define IP_PROT_TCP 0x06

parser parse_ipv4 {
    extract(ipv4);
    // Get the ipv4 protocol value
	// and select which function to run
    return select(ipv4.protocol){
        IP_PROT_TCP : parse_tcp; // Go to parser parse_tcp
        default     : ingress; 	// Go to control ingress
    }
}

parser parse_tcp {
    extract(tcp);
    return ingress;	// Go to control ingress
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

// These values must be same as the values in the commands.txt
#define CPU_MIRROR_SESSION_ID                   250

// Just defined to be able to use the clone_ingress_pkt_to_egress
field_list copy_to_cpu_fields {
    standard_metadata;
}

// Basic drop action
action _drop() {
    drop();
}

// Saves the ip we want to mirror in the ip_mirror_meta.ip 
// for future use and sends a copy of the incomming packet 
action do_copy_to_cpu(){
    modify_field(ip_mirror_meta.ip, ipv4.srcAddr);
    clone_ingress_pkt_to_egress(CPU_MIRROR_SESSION_ID, copy_to_cpu_fields);
}

table copy_to_cpu {
    reads {
        // Checks if the incomming packet's source 
        // IP address is available in the copy_to_cpu 
        // table in the commands.txt
        ipv4.srcAddr : exact;
    }
    actions {
        do_copy_to_cpu;
        _drop;
    }
    size : 1024;
}

action set_nhop(nhop_ipv4, port){
    modify_field(custom_metadata.nhop_ipv4, nhop_ipv4);
    modify_field(standard_metadata.egress_spec, port);
    add_to_field(ipv4.ttl, -1);
}

// Specify the egress_spec according to the ip address
// in the commands.txt
table ipv4_lpm {
    reads {
        ipv4.dstAddr : lpm;
    }
    actions {
        set_nhop;
        _drop;
    }
    size: 1024;
}

action set_dmac(dmac){
    modify_field(ethernet.dstAddr, dmac);
}

// Set destination mac according to the ip address 
// in the commands.txt
table forward {
    reads {
        // Match the nhop ip address from commands.txt
        custom_metadata.nhop_ipv4 : exact;
    }
    actions {
        set_dmac;
        _drop;
    }
    size: 1024;
}

control ingress {

    // Copy the incoming packet to the CPU if the 
    // destination IP to mirror is in the copy_to_cpu table 
    // inside the commands.txt file
    apply(copy_to_cpu);

    // Get the next hop from the table inside commands.txt
    apply(ipv4_lpm);

    // Set destination mac address and forward the packet
    apply(forward);
}

/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

action rewrite_mac(smac) {
    modify_field(ethernet.srcAddr, smac);
}

table send_frame {
    reads {
        standard_metadata.egress_port: exact;
    }
    actions {
        rewrite_mac;
        _drop;
    }
    size: 1024;
}

control egress {

	// Drop the packets coming from the CPU pipelane and 
	// resend only original incoming packets
    if(standard_metadata.instance_type != 1){
        apply(send_frame);    
    }
}
