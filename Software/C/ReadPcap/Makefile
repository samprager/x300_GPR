CC=gcc

SRT =  read_pcap.c
# SRC =
OBJ = $(SRC:.c=.o) $(SRT:.c=.o)

CFLAGS = -Wall -g
LDFLAGS= -lpcap

read_pcap: $(OBJ)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

read_pcap.o: read_pcap.c
	$(CC) $(CFLAGS) -c $<

clean:
	rm -f $(OBJ)
