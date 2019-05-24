/* Combinational Comparison with SAT */

/*	This program takes the names of two files from the command line.
	The files should describe circuits in ISCAS 85 format.
	The program will dump out a SAT problem in DIMACS cnf format
	which is satisfiable iff the circuits are different.
	The comments in the DIMACS file will contain the names of
	the inputs and outputs and their corresponding variable
	numbers in the DIMACS file, to make it easier to interpret
	the results.  (It'd be good to write a little perl script
	or something to print out the results nicely, saying what
	what input will make the circuits have different output.
*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define MAXLINE 256	/* Maximum length of each input line read. */

/* Definitions of wire types, used in type field of wire structure. */
#define	INPUT	0	/* Primary input */
#define	AND	1
#define	NAND	2
#define	OR	3
#define NOR	4
#define XOR	5
#define XNOR	6	/* Are inputs equal? */
#define BUFF	7	/* Non-inverting buffer:  output = input */
#define NOT	8
#define FROM	9	/* Fanout branch:  output = input */

struct wire_	{
			char	*name;		/* Name of this wire. */
			int	type;	/* Type of gate driving this wire. */
			int	fanincount;	/* Number of fanins. */
			int	*fanins;	/* Array of fanin indices. */
			int	var_num;	/* DIMACS variable num for this wire. */
		};
typedef struct wire_ *wire;

struct circuit_	{
			char	*name;		/* Name of the circuit. */
			int	wirecount;	/* Number of wire indices. */
			wire	*wires;		/* Array of all wires */
			int	inputcount;	/* Number of primary inputs. */
			int	*inputs;	/* Array of input indices. */
			int	outputcount;	/* Number of primary outputs. */
			int	*outputs;	/* Array of output indices. */
		};
typedef struct circuit_ *circuit;

int translate_wiretype(char *typename)
	/* Helper function for parse_iscas85(). */
	/* Returns the wire type constant for the given string. */
{
    if (strncmp("inpt",typename,4)==0) return INPUT;
    if (strncmp("and",typename,4)==0) return AND;
    if (strncmp("nand",typename,4)==0) return NAND;
    if (strncmp("or",typename,4)==0) return OR;
    if (strncmp("nor",typename,4)==0) return NOR;
    if (strncmp("xor",typename,4)==0) return XOR;
    if (strncmp("xnor",typename,4)==0) return XNOR;
    if (strncmp("buff",typename,4)==0) return BUFF;
    if (strncmp("not",typename,4)==0) return NOT;
    if (strncmp("from",typename,4)==0) return FROM;

    fprintf(stderr,"cmbcmp:  Illegal wire type \"%s\"\n",typename);
    exit(1);
}

int parse_iscas85(FILE *f, circuit c)
	/* Reads an ISCAS 85 circuit from stream f, building up circuit c. */
{
    int inputcount = 0;
    int outputcount = 0;
    int maxindex = -1;
    char linebuf[MAXLINE];
    int index, fanins, fanouts;
    char wirename[MAXLINE], wiretype[MAXLINE];
    int i;
    int fanindex;

    /* Make first pass to count primary inputs, primary outputs, and wires. */
    while (fgets(linebuf,MAXLINE,f) != NULL) {
	if (linebuf[0]=='*') continue;	/* Skip comment lines. */

	/* Pick out the relevant data from the line. */
	sscanf(linebuf,"%d %*s %*s %d %d",&index,&fanouts,&fanins);
	if (index>maxindex) maxindex = index;
	if (fanouts==0) outputcount++;	/* Only outputs have no fanout. */
	if (fanins==0) inputcount++;	/* Only inputs have no fanin. */
	if (fanins>0) fgets(linebuf,MAXLINE,f);	/* Discard fanin line. */
	if (fanouts>1) {
	    while (fanouts-- > 0)
		fgets(linebuf,MAXLINE,f);	/* Discard fanout lines. */
	}
    }

    /* Now that we know how big to make the arrays, allocate memory. */
    c->wirecount = maxindex+1;
    /* Allocate a contiguous array we can index for every wire. */
    c->wires = (wire *)malloc((maxindex+1)*sizeof(wire));
    bzero(c->wires,(maxindex+1)*sizeof(wire));	/* Clear out the space. */
    c->inputcount = inputcount;
    c->inputs = (int *)malloc(inputcount*sizeof(int));
    c->outputcount = outputcount;
    c->outputs = (int *)malloc(outputcount*sizeof(int));

    /* Second pass actually reads the circuit. */
    rewind(f);
    inputcount = 0;
    outputcount = 0;
    while (fgets(linebuf,MAXLINE,f) != NULL) {
	if (linebuf[0]=='*') continue;	/* Skip comment lines. */

	/* Pick out the relevant data from the line. */
	sscanf(linebuf,"%d %s %s %d %d",&index,wirename,wiretype,&fanouts,&fanins);

	/* Create the new wire. */
	c->wires[index] = (wire)malloc(sizeof(struct wire_));
	c->wires[index]->name = strdup(wirename);
	c->wires[index]->type = translate_wiretype(wiretype);
	c->wires[index]->fanincount = fanins;
	c->wires[index]->fanins = (int *)malloc(sizeof(int)*fanins);

	/* If it's a primary input or primary output, record that fact. */
	if (fanins==0) c->inputs[inputcount++] = index; /* primary input. */
	if (fanouts==0) c->outputs[outputcount++] = index; /* primary output. */

	/* Read the fanins. */
	if (fanins>0) {
	    for (i=0; i<fanins; i++) {
		fscanf(f,"%d",&(c->wires[index]->fanins[i]));
	    }
	    fgets(linebuf,MAXLINE,f);	/* Discard rest of line. */
	}

	/* Read the fanout lines if fanouts>1. */
	if (fanouts>1) {
	    for (i=0; i<fanouts; i++) {
		/* This is annoying.  I need to create additional wires for
		   each fanout because of the way the input format works. */
		fscanf(f,"%d %s",&fanindex,wirename);
		/* Create the fanout branch wire. */
		c->wires[fanindex] = (wire)malloc(sizeof(struct wire_));
		c->wires[fanindex]->name = strdup(wirename);
		c->wires[fanindex]->type = FROM;
		c->wires[fanindex]->fanincount = 1;
		c->wires[fanindex]->fanins = (int *)malloc(sizeof(int));
		c->wires[fanindex]->fanins[0] = index;
		fgets(linebuf,MAXLINE,f);	/* Discard rest of line. */
	    }
	}
    }

    return 1;	/* Didn't bother to do any error checking. */
}

circuit read_iscas85_file(char *filename)
	/* This routine reads in an ISCAS 85 format circuit from the file. */
{
    FILE *f;
    circuit c;
    int i;
	
    f = fopen(filename,"r");
    if (!f) {
	fprintf(stderr,"cmbcmp:  cannot open file \"%s\"\n",filename);
	return NULL;
    }

    c = (circuit)malloc(sizeof(*c));
    if (!c) {
	fprintf(stderr,"cmbcmp:  cannot allocate memory\n");
	return NULL;
    }

    c->name = filename;

    /* Parse the circuit into c, returning NULL if error. */
    if (!parse_iscas85(f,c)) {
	fprintf(stderr,"cmbcmp:  error reading circuit in file \"%s\"\n",filename);
	free((void *)c);
	return NULL;
    }

    /* Fill in any "holes" in wire array, to make rest of code easier. */
    for (i=0; i < c->wirecount; i++)
	if (c->wires[i] == NULL) {
	    c->wires[i] = (wire)malloc(sizeof(struct wire_));
	    c->wires[i]->name = "BogusHole";
	    c->wires[i]->type = INPUT;	/* So no fanins */
	    c->wires[i]->fanincount = 0;
	    c->wires[i]->fanins = NULL;
	}

    fclose(f);

    return c;
}

int no_printf(const char *format, ...)
{
	/* Do nothing function to turn off printing. */
	return 0;
}

int make_clauses(circuit c, int print(const char *format, ...))
	/* Generates clauses for circuit c.  Returns number of clauses.
		Only prints the clauses if print is nonzero. */
{
    int i, j;
    int clausecount = 0;

    for (i=0; i < c->wirecount; i++) {

	print("c gate %s ", c->wires[i]->name);

	switch (c->wires[i]->type) {
	    case INPUT:
		print("INPUT\n");	/* Continuation of comment */
		/* No clauses need to be generated. */
		break;
	    case AND:
		print("AND\n");	/* Continuation of comment */
		/* If any input is 0, the output is 0. */
		for (j=0; j < c->wires[i]->fanincount; j++) {
		    print("%d -%d 0\n",
				c->wires[c->wires[i]->fanins[j]]->var_num,
				c->wires[i]->var_num);
		    clausecount++;
		}
		/* If all inputs are 1, the output must be 1. */
		for (j=0; j < c->wires[i]->fanincount; j++) {
		    print("-%d ", c->wires[c->wires[i]->fanins[j]]->var_num);
		}
		print("%d 0\n", c->wires[i]->var_num);
		clausecount++;
		break;
	    case NAND:
		print("NAND\n");	/* Continuation of comment */
		/* If any input is 0, the output is 1. */
		for (j=0; j < c->wires[i]->fanincount; j++) {
		    print("%d %d 0\n",
				c->wires[c->wires[i]->fanins[j]]->var_num,
				c->wires[i]->var_num);
		    clausecount++;
		}
		/* If all inputs are 1, the output must be 0. */
		for (j=0; j < c->wires[i]->fanincount; j++) {
		    print("-%d ", c->wires[c->wires[i]->fanins[j]]->var_num);
		}
		print("-%d 0\n", c->wires[i]->var_num);
		clausecount++;
		break;
	    case OR:
		print("OR\n");	/* Continuation of comment */
		/* FIX THIS!!! */
		/* YOUR CODE GOES HERE. */
		break;
	    case NOR:
		print("NOR\n");	/* Continuation of comment */
		/* FIX THIS!!! */
		/* YOUR CODE GOES HERE. */
		break;
	    case XOR:
		print("XOR\n");	/* Continuation of comment */
		/* If both inputs 0, output must be 0. */
		print("%d %d -%d 0\n",
			c->wires[c->wires[i]->fanins[0]]->var_num,
			c->wires[c->wires[i]->fanins[1]]->var_num,
			c->wires[i]->var_num);
		clausecount++;
		/* If one in put 1, the other input 0, output must be 1. */
		print("-%d %d %d 0\n",
			c->wires[c->wires[i]->fanins[0]]->var_num,
			c->wires[c->wires[i]->fanins[1]]->var_num,
			c->wires[i]->var_num);
		clausecount++;
		print("%d -%d %d 0\n",
			c->wires[c->wires[i]->fanins[0]]->var_num,
			c->wires[c->wires[i]->fanins[1]]->var_num,
			c->wires[i]->var_num);
		clausecount++;
		/* If both inputs 1, output must be 0. */
		print("-%d -%d -%d 0\n",
			c->wires[c->wires[i]->fanins[0]]->var_num,
			c->wires[c->wires[i]->fanins[1]]->var_num,
			c->wires[i]->var_num);
		clausecount++;
		break;
	    case XNOR:
		print("XNOR\n");	/* Continuation of comment */
		/* If both inputs 0, output must be 1. */
		print("%d %d %d 0\n",
			c->wires[c->wires[i]->fanins[0]]->var_num,
			c->wires[c->wires[i]->fanins[1]]->var_num,
			c->wires[i]->var_num);
		clausecount++;
		/* If one in put 1, the other input 0, output must be 0. */
		print("-%d %d -%d 0\n",
			c->wires[c->wires[i]->fanins[0]]->var_num,
			c->wires[c->wires[i]->fanins[1]]->var_num,
			c->wires[i]->var_num);
		clausecount++;
		print("%d -%d -%d 0\n",
			c->wires[c->wires[i]->fanins[0]]->var_num,
			c->wires[c->wires[i]->fanins[1]]->var_num,
			c->wires[i]->var_num);
		clausecount++;
		/* If both inputs 1, output must be 1. */
		print("-%d -%d %d 0\n",
			c->wires[c->wires[i]->fanins[0]]->var_num,
			c->wires[c->wires[i]->fanins[1]]->var_num,
			c->wires[i]->var_num);
		clausecount++;
		break;
	    case BUFF:
		print("BUFF\n");	/* Continuation of comment */
		/* If input is 0, output must be 0. */
		print("%d -%d 0\n",
			c->wires[c->wires[i]->fanins[0]]->var_num,
			c->wires[i]->var_num);
		clausecount++;
		/* If input is 1, output must be 1. */
		print("-%d %d 0\n",
			c->wires[c->wires[i]->fanins[0]]->var_num,
			c->wires[i]->var_num);
		clausecount++;
		break;
	    case NOT:
		print("NOT\n");	/* Continuation of comment */
		/* FIX THIS!!! */
		/* YOUR CODE GOES HERE. */
		break;
	    case FROM:
		print("FROM\n");	/* Continuation of comment */
		/* If input is 0, output must be 0. */
		print("%d -%d 0\n",
			c->wires[c->wires[i]->fanins[0]]->var_num,
			c->wires[i]->var_num);
		clausecount++;
		/* If input is 1, output must be 1. */
		print("-%d %d 0\n",
			c->wires[c->wires[i]->fanins[0]]->var_num,
			c->wires[i]->var_num);
		clausecount++;
		break;
	    default:
		fprintf(stderr,"Error:  Illegal wire type %d on wire %s.\n",
			c->wires[i]->type, c->wires[i]->name);
		exit(1);
	}
    }

    return clausecount;
}


int main(int argc, char *argv[])
{
    circuit circuit1, circuit2;
    int i;
    int circuit1_clauses, circuit2_clauses;

    /* Make sure program invoked with two arguments. */
    if (argc !=3) {
	fprintf(stderr,"cmbcmp-sat:  usage:  cmbcmp-sat file1 file2\n");
	exit(1);
    }

    circuit1 = read_iscas85_file(argv[1]);
    if (!circuit1) exit(1);
    circuit2 = read_iscas85_file(argv[2]);
    if (!circuit2) exit(1);
    /* Check that the two circuits have the same inputs. */
    if (circuit1->inputcount != circuit2->inputcount) {
	printf("Circuits have different number of inputs:\n");
	printf("\tCircuit \"%s\" has %d inputs.\n",
				circuit1->name,circuit1->inputcount);
	printf("\tCircuit \"%s\" has %d inputs.\n",
				circuit2->name,circuit2->inputcount);
	exit(0);
    }
    for (i=0; i < circuit1->inputcount; i++) {
	/* Make sure all the names agree. */
	if (strcmp(circuit1->wires[circuit1->inputs[i]]->name,
		   circuit2->wires[circuit2->inputs[i]]->name)!=0) {
	    printf("Primary input %d differs between circuits:\n",i);
	    printf("\tIn circuit \"%s\", input %d is named \"%s\".\n",
		circuit1->name,i,circuit1->wires[circuit1->inputs[i]]->name);
	    printf("\tIn circuit \"%s\", input %d is named \"%s\".\n",
		circuit2->name,i,circuit2->wires[circuit2->inputs[i]]->name);
	    exit(0);
	}
    }

    /* Check that the two circuits have the same outputs. */
    if (circuit1->outputcount != circuit2->outputcount) {
	printf("Circuits have different number of outputs:\n");
	printf("\tCircuit \"%s\" has %d outputs.\n",
				circuit1->name,circuit1->outputcount);
	printf("\tCircuit \"%s\" has %d outputs.\n",
				circuit2->name,circuit2->outputcount);
	exit(0);
    }
    for (i=0; i < circuit1->outputcount; i++) {
	/* Make sure all the names agree. */
	if (strcmp(circuit1->wires[circuit1->outputs[i]]->name,
		   circuit2->wires[circuit2->outputs[i]]->name)!=0) {
	    printf("Primary output %d differs between circuits:\n",i);
	    printf("\tIn circuit \"%s\", output %d is named \"%s\".\n",
		circuit1->name,i,circuit1->wires[circuit1->outputs[i]]->name);
	    printf("\tIn circuit \"%s\", output %d is named \"%s\".\n",
		circuit2->name,i,circuit2->wires[circuit2->outputs[i]]->name);
	    exit(0);
	}
    }

    /* OK, at this point, we know the two circuits have corresponding
	inputs and outputs.  Your mission is compare the logical functionality
	of the two circuits.  Good luck! */

    /* DIMACS format requires the variables be numbered from 1 to n.
       Let's assign a variable for each wire in each circuit.
       (We'll have a few more variables at the end to compare
       the outputs.) */
    for (i=0; i < circuit1->wirecount; i++)
	circuit1->wires[i]->var_num = i+1;
    for (i=0; i < circuit2->wirecount; i++)
	circuit2->wires[i]->var_num = i+1 + circuit1->wirecount;

    /* DIMACS format starts by saying how many variables and how
	many clauses there are.  The number of variables is pretty
	easy, but the number of clauses requires going through
	the whole circuit, essentially doing the work of generating
	all the needed clauses.  I'm going to use the same routine
	to count clauses as to generate them, and I'll give it an
	argument whether to print it's clauses or not. */
    /* Generates and counts clauses, but doesn't print them. */
    circuit1_clauses = make_clauses(circuit1,no_printf);
    circuit2_clauses = make_clauses(circuit2,no_printf);
    /* OK, output the preamble... */
    printf("p cnf ");
    printf("%d ",circuit1->wirecount + circuit2->wirecount +
		circuit1->outputcount);
		/* we need an extra wire to be the result of comparing
			each output */
    printf("%d\n",circuit1_clauses + circuit2_clauses +
		2*circuit1->inputcount +
		4*circuit1->outputcount +
		1);
    /* tying each pair of inputs together needs 2 clauses,
	comparing each output needs 4 clauses, and then there's
	a final clause to say at least one output differs */
    
    /* OK, now generate clauses for the circuits */
    printf("c ----- Circuit 1 Clauses -----\n");
    (void) make_clauses(circuit1,printf);
    printf("c ----- Circuit 2 Clauses -----\n");
    (void) make_clauses(circuit2,printf);

    /* Now, we have to generate clauses to tie together corresponding inputs.
    */
    for (i=0; i < circuit1->inputcount; i++) {
	printf("c Tie together inputs %d\n", i);
	printf("%d -%d 0\n", circuit1->wires[circuit1->inputs[i]]->var_num,
			    circuit2->wires[circuit2->inputs[i]]->var_num);
	printf("-%d %d 0\n", circuit1->wires[circuit1->inputs[i]]->var_num,
			    circuit2->wires[circuit2->inputs[i]]->var_num);
    }
    /* Next, we have to generate clauses to check whether the outputs agree.
	Basically, for each output pair, we'll create an XOR gate.  If
	the outputs disagree, the XOR gate will output a 1.
    */
    for (i=0; i < circuit1->outputcount; i++) {
	int xor_var_num = circuit1->wirecount + circuit2->wirecount + i + 1;
	printf("c XOR for outputs %d\n", i);
	printf("%d %d -%d 0\n", circuit1->wires[circuit1->outputs[i]]->var_num,
			      circuit2->wires[circuit2->outputs[i]]->var_num,
			      xor_var_num);
	printf("%d -%d %d 0\n", circuit1->wires[circuit1->outputs[i]]->var_num,
			      circuit2->wires[circuit2->outputs[i]]->var_num,
			      xor_var_num);
	printf("-%d %d %d 0\n", circuit1->wires[circuit1->outputs[i]]->var_num,
			      circuit2->wires[circuit2->outputs[i]]->var_num,
			      xor_var_num);
	printf("-%d -%d -%d 0\n", circuit1->wires[circuit1->outputs[i]]->var_num,
			      circuit2->wires[circuit2->outputs[i]]->var_num,
			      xor_var_num);
    }

    /* And finally, a clause to say that at least one output differs. */
    printf("c Assert that at least one of the above XORs is true.\n");
    /* FIX THIS!!! */
    /* YOUR CODE GOES HERE. */

    return 0;
}
