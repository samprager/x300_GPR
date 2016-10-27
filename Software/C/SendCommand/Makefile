CC=gcc

SRT =  sendcommand.c
# SRC =
OBJ = $(SRC:.c=.o) $(SRT:.c=.o)

CFLAGS = -Wall -g
LDFLAGS= -lpcap

sendcommand: $(OBJ)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

sendcommand.o: sendcommand.c sendcommand.h
	$(CC) $(CFLAGS) -c $<

clean:
	rm -f $(OBJ)
