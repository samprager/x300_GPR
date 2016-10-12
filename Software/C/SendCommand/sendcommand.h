
//
//  sendcommand.h
//
//
//  Created by Sam Prager on 6/10/16.
//
//

#ifndef sendcommand_h
#define sendcommand_h

#include <pcap.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <net/ethernet.h>
#include <netinet/if_ether.h>
#include <netinet/ip.h>
#include <string.h>
#include <sys/types.h>
#include <sys/ioctl.h>

#include <unistd.h>
#include <net/if.h>
#include <netdb.h>

void my_callback(u_char *user, const struct pcap_pkthdr *pkthdr, const u_char *packet);

char* readFile(char *filename);


#endif /* sendcommand_h */
