
//
//  sendcommand.c
//
//
//  Created by Sam Prager on 6/20/15.
//
//

#include "sendcommand.h"

#define DEST_MAC0	0x00
#define DEST_MAC1	0x00
#define DEST_MAC2	0x00
#define DEST_MAC3	0x00
#define DEST_MAC4	0x00
#define DEST_MAC5	0x00

void my_callback(u_char *user, const struct pcap_pkthdr *pkthdr, const u_char *packet) {

    int i = 0;
    int k = 0;

    for (i = 0; i < pkthdr->len; i++) {
        if ((i % 16) == 0) {
            fprintf(stdout, "\n%03x0\t", k);
            k++;
        }
        fprintf(stdout, "%02x ", packet[i]);
    }

    fprintf(stdout, "\n*******************************************************\n");

    u_char ethernet_packet[14];
    u_char ip_header[24];
    u_char udp_header[8];
    int udp_header_start = 34;
    int data_length;

    for (i = 0; i < 14; i++) {
        ethernet_packet[i] = packet[0 + i];
    }

    fprintf(stdout, "Destination Address\t\t%02X:%02X:%02X:%02X:%02X:%02X\n", ethernet_packet[0], ethernet_packet[1], ethernet_packet[2], ethernet_packet[3], ethernet_packet[4], ethernet_packet[5]);
    fprintf(stdout, "Source Address\t\t\t%02X:%02X:%02X:%02X:%02X:%02X\n", ethernet_packet[6], ethernet_packet[7], ethernet_packet[8], ethernet_packet[9], ethernet_packet[10], ethernet_packet[11]);

    if (ethernet_packet[12] == 0x08 &&
        ethernet_packet[13] == 0x00) {

        fprintf(stdout, "Ethertype\t\t\t\tIP Packet\n");

        for (i = 0; i < 20; i++) {
            ip_header[i] = packet[14 + i];
        }

        fprintf(stdout, "Version\t\t\t\t\t%d\n", (ip_header[0] >> 4));
        fprintf(stdout, "IHL\t\t\t\t\t\t%d\n", (ip_header[0] & 0x0F));
        fprintf(stdout, "Type of Service\t\t\t%d\n", ip_header[1]);
        fprintf(stdout, "Total Length\t\t\t%d\n", ip_header[2]);
        fprintf(stdout, "Identification\t\t\t0x%02x 0x%02x\n", ip_header[3], ip_header[4]);
        fprintf(stdout, "Flags\t\t\t\t\t%d\n", ip_header[5] >> 5);
        fprintf(stdout, "Fragment Offset\t\t\t%d\n", (((ip_header[5] & 0x1F) << 8) + ip_header[6]));
        fprintf(stdout, "Time To Live\t\t\t%d\n", ip_header[7]);
        if (ip_header[9] == 0x11) {

            fprintf(stdout, "Protocol\t\t\t\tUDP\n");
        }
        else {
            fprintf(stdout, "Protocol\t\t\t\t%d\n", ip_header[9]);
        }
        fprintf(stdout, "Header Checksum\t\t\t0x%02x 0x%02x\n", ip_header[10], ip_header[11]);
        fprintf(stdout, "Source Address\t\t\t%d.%d.%d.%d\n", ip_header[12], ip_header[13], ip_header[14], ip_header[15]);
        fprintf(stdout, "Destination Address\t\t%d.%d.%d.%d\n", ip_header[16], ip_header[17], ip_header[18], ip_header[19]);
        if ((ip_header[0] & 0x0F) > 5) {
            udp_header_start = 48;
            fprintf(stdout, "Options\t\t\t\t\t0x%02x 0x%02x 0x%02x 0x%02x\n", ip_header[20], ip_header[21], ip_header[22], ip_header[23]);
        }

        if (ip_header[9] == 0x11) {

            fprintf(stdout, "\t\t\t\tUDP HEADER\n");

            for (i = 0; i < 8; i++) {
                udp_header[i] = packet[udp_header_start + i];
            }

            fprintf(stdout, "Source Port\t\t\t\t%d\n", (udp_header[0] << 8) + udp_header[1]);
            fprintf(stdout, "Destination Port\t\t%d\n", (udp_header[2] << 8) + udp_header[3]);
            fprintf(stdout, "Length\t\t\t\t\t%d\n", (udp_header[4] << 8) + udp_header[5]);
            fprintf(stdout, "Checksum\t\t\t\t0x%02x 0x%02x\n", udp_header[6], udp_header[7]);

            data_length = pkthdr->len - (udp_header_start + 8);

            fprintf(stdout, "Data\n");
            for (i = 0; i < data_length; i++) {

                fprintf(stdout, "%02x ", packet[udp_header_start + 8 + i]);
            }
            fprintf(stdout, "\n");
        }
    }
    else {
        fprintf(stdout, "Ethertype\t\t\t\tUnknow\n");
    }
}


char* readFile(char *filename)
{
   char *buffer = NULL;
   int string_size, read_size;
   FILE *fd = fopen(filename, "r");

   if (fd)
   {
       // Seek the last byte of the file
       fseek(fd, 0, SEEK_END);
       // Offset from the first to the last byte, or in other words, filesize
       string_size = ftell(fd);
       // go back to the start of the file
       rewind(fd);

       // Allocate a string that can hold it all
       buffer = (char*) malloc(sizeof(char) * (string_size + 1) );

       // Read it all in one operation
       read_size = fread(buffer, sizeof(char), string_size, fd);

       // fread doesn't set it so put a \0 in the last position
       // and buffer is now officially a string
       buffer[string_size] = '\0';

       if (string_size != read_size)
       {
           // Something went wrong, throw away the memory and set
           // the buffer to NULL
           free(buffer);
           buffer = NULL;
       }

       // Always remember to close the file.
       fclose(fd);
    }

    return buffer;
}

int main(int argc,char **argv) {
    int i;
    char *dev;
    char errbuf[PCAP_ERRBUF_SIZE];
    pcap_t* descr;
    struct bpf_program fp;
    bpf_u_int32 maskp;
    bpf_u_int32 netp;

    const char* if_name= "en0";//argv[1];
    const char* target_ip_string= "192.168.1.10";//argv[2];
    const char* target_mac_string = "5a:01:02:03:04:05";
    u_char target_mac[6] = {0x5a,0x01,0x02,0x03,0x04,0x05};

    uint16_t packet_size = 480;
    uint16_t packet_counter;

    u_char *packet_data = (u_char *)malloc(packet_size*sizeof(u_char));
    for (i=0;i<packet_size;i++){
      packet_data[i] = i;
    }

    // Construct Ethernet header (except for source MAC address).
    // (Destination set to broadcast address, FF:FF:FF:FF:FF:FF.)
    struct ether_header header;
    //header.ether_type=htons(ETH_P_ARP);
    header.ether_type=htons(packet_size);
  //  memset(header.ether_dhost,0xff,sizeof(header.ether_dhost));
    for (i=0;i<6;i++) header.ether_dhost[i] = target_mac[i];

    // Convert target IP address from string, copy into ARP request.
    struct in_addr target_ip_addr={0};
    if (!inet_aton(target_ip_string,&target_ip_addr)) {
        fprintf(stderr,"%s is not a valid IP address",target_ip_string);
        exit(1);
    }

    // Write the interface name to an ifreq structure,
    // for obtaining the source MAC and IP addresses.
    struct ifreq ifr;
    size_t if_name_len=strlen(if_name);
    if (if_name_len<sizeof(ifr.ifr_name)) {
        memcpy(ifr.ifr_name,if_name,if_name_len);
        ifr.ifr_name[if_name_len]=0;
    } else {
        fprintf(stderr,"interface name is too long");
        exit(1);
    }

    // Open an IPv4-family socket for use when calling ioctl.
    int fd=socket(AF_INET,SOCK_DGRAM,0);
    if (fd==-1) {
        perror(0);
        exit(1);
    }

    // Obtain the source IP address, copy into ARP request
    // if (ioctl(fd,SIOCGIFADDR,&ifr)==-1) {
    //     perror(0);
    //     close(fd);
    //     exit(1);
    // }
    // struct sockaddr_in* source_ip_addr = (struct sockaddr_in*)&ifr.ifr_addr;

    struct sockaddr_in* source_ip_addr=inet_addr("192.168.1.1");

    // Obtain the source MAC address, copy into Ethernet header and ARP request.
    // if (ioctl(fd,SIOCGIFADDR,&ifr)==-1) {
    //
    //     perror(0);
    //     close(fd);
    //     exit(1);
    // }
    // if (ifr.ifr_addr.sa_family!=ARPHRD_ETHER) {
    //     fprintf(stderr,"not an Ethernet interface");
    //     close(fd);
    //     exit(1);
    // }
    // const unsigned char* source_mac_addr=(unsigned char*)ifr.ifr_addr.sa_data;
    // memcpy(header.ether_shost,source_mac_addr,sizeof(header.ether_shost));

    u_char source_mac[6]={0x98,0x5a,0xeb,0xdb,0x06,0x6f};
    for (i=0;i<6;i++) header.ether_shost[i] = source_mac[i];


    close(fd);

    // Combine the Ethernet header and ARP request into a contiguous block.
    unsigned char frame[sizeof(struct ether_header)+ packet_size];
    memcpy(frame,&header,sizeof(struct ether_header));
    memcpy(frame+sizeof(struct ether_header),packet_data,packet_size);

    for (i=0;i<sizeof(struct ether_header)+ packet_size;i++){
      printf("%02x ",frame[i]);
    }

    // Open a PCAP packet capture descriptor for the specified interface.
    char pcap_errbuf[PCAP_ERRBUF_SIZE];
    pcap_errbuf[0]='\0';
    pcap_t* pcap=pcap_open_live(if_name,96,0,0,pcap_errbuf);
    if (pcap_errbuf[0]!='\0') {
        fprintf(stderr,"%s\n",pcap_errbuf);
    }
    if (!pcap) {
        exit(1);
    }

    for(i=0;i<10;i++){
    // Write the Ethernet frame to the interface.
    if (pcap_inject(pcap,frame,sizeof(frame))==-1) {
        pcap_perror(pcap,0);
        pcap_close(pcap);
        exit(1);
    }

  }

    // Close the PCAP descriptor.
    pcap_close(pcap);
    return 0;

    // dev = pcap_lookupdev(errbuf);
    // printf("dev: %s\n",dev);
    // if(dev == NULL) {
    //     fprintf(stderr,"%s\n",errbuf); exit(1);
    // }
/*
    dev = "en0";

    pcap_lookupnet(dev, &netp, &maskp, errbuf);
    descr = pcap_open_live(dev, BUFSIZ, 1, 1000, errbuf);

    if(descr == NULL) {
        printf("pcap_open_live(): %s\n",errbuf);
        exit(1);
    }

    char filter[] = "udp";
    if(pcap_compile(descr,&fp, filter,0,netp) == -1) {
        fprintf(stderr,"Error calling pcap_compile\n");
        exit(1);
    }

    if(pcap_setfilter(descr,&fp) == -1) {
        fprintf(stderr,"Error setting filter\n");
        exit(1);

    }

    //pcap_loop(descr,-1,my_callback,NULL);

    // write a packet
     //define a new packet and for each position set its values
     u_char packet[86];
     u_char dest_val[16];
     char *savedpacket = readFile("savedpacket.txt");
     puts(savedpacket);
     for(int i = 0; i<16; i++)
     {
       sscanf(&savedpacket[i*2],"%2hhx",&dest_val[i]); // Everytime we read two chars --> %x%x
     }
    for(int i = 0; i<16; i++){
      printf("%02x ",dest_val[i]);
    }

     for (int i=0;i<86;i++) packet[i] = 0xAA;

     // Send down the packet
     for (int i=0;i<1000;i++){
     if (pcap_sendpacket(descr, packet, 86) != 0) {

     fprintf(stderr,"\nError sending the packet: %s\n", pcap_geterr(descr));
     return 2;
     }
   }
   free(savedpacket);
    return 0;
    */
}
