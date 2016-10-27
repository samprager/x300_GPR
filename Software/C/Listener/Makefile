CC=gcc

SRT =  packet_rx.c
# SRC =
OBJ = $(SRC:.c=.o) $(SRT:.c=.o)

CFLAGS = -Wall -g
LDFLAGS= -lpcap

packet_rx: $(OBJ)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

packet_rx.o: packet_rx.c
	$(CC) $(CFLAGS) -c $<

clean:
	rm -f $(OBJ)
