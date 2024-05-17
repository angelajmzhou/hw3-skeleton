	# Data section messages.
	.data
message:   .asciz "Need To Implement\n"
	
	## Code section
	.text
	.globl createHashTable
	.globl insertData
	.globl findData

#struct HashBucket {
#  void *key;
#  void *data;
#  struct HashBucket *next;
#};

#typedef struct HashTable {
#  unsigned int (*hashFunction)(void *);
#  int (*equalFunction)(void *, void *);
#  struct HashBucket **data;
#  int size;
#  int used;
#} HashTable;


#HashTable *createHashTable(int size,
#                           unsigned int (*hashFunction)(void *),
#                           int (*equalFunction)(void *, void *));createHashTable:
	addi sp sp -20
	sw ra 0(sp) 
	sw s0 4(sp)		 
	sw s1 8(sp) 
	sw s2 12(sp) 
	sw s3 16(sp)	 #for the newTable
	mv s0 a0		 #store size	
	mv s1 a1		#store hashFunction pointer
	mv s2 a2		#store equalFunction pointer
	li a0 20 		#sizeofHashtable as argument
	call malloc 	#malloc
	mv s3 a0 		#HashTable *newTable = malloc(sizeof(HashTable))
	sw s0 12(s3)	#newTable -> size = size
	sw x0 16(s3)	#newTable -> used = 0
	li t2 4			#size of hashbucket pointer
	mul t2 t2 s0	#hashbucket*size
	mv a0 t2		#argument is size(hashbucket *) * size
	call malloc		#malloc HashBucket
	sw a0 8(s3)		#newTable->data = malloc(sizeof(struct HashBucket *) * size)
	li t0 0			#i=0
	loop_start: 
	slli t3 t0 2 		#"multiply" i by 4 (4 bytes), store in t3
	add t3 a0 t3 		#add the offset to the data address, store in t3
	sw x0 0(t3)			#store null in the data ie. *(*data+4i) = NULL
	addi t0 t0 1 		#increment
	bge t0 s0 loop_start 	#loop condition
	sw s1 0(s3)		#newTable->hashFunction = hashFunction;
  	sw s2 4(s3)		#newTable->equalFunction = equalFunction;
	mv a0 s3
	lw s3 16(sp) 	#restore the newTable
	lw s2 12(sp)	 #restore equalFunction pointer
	lw s1 8(sp) 	#restore hashFunction pointer
	lw s0 4(sp) 	#restore size
	lw ra 0(sp)
	addi sp sp 20
	ret

# void insertData(HashTable *table, void *key, void *data);
insertData:
	addi sp sp -20
	sw ra 0(sp) 	#for return address
	sw s0 4(sp) 	#for table pointer
	sw s1 8(sp) 	#for key pointer
	sw s2 12(sp) 	#for data pointer
	sw s3 16(sp) 	#for newBucket
	mv s0 a0		#s0 contains table
	mv s1 a1		
	mv s2 a2
	li a0 12		#sizeof(struct HashBucket)
	call malloc		#malloc that much space
	mv s3 a0 		#ie: *newBucket (s3) = malloc... (both pointers)
	mv a0 s1 		#set key up as parameter
	lw t1 0(s0)
	jalr ra 0(t1)	#run hashFunction on key
	mv t5 a0		#t5 = hashFunction(key)
	lw t1 12(s0) 	#t2 = table -> size
	rem t5 t5 t2	#t5 = ((table->hashFunction)(key)) % table->size;
	mv t0 x0 		#initialize int (t0) location = 0
	mv t0 t5 		# location  = ((table->hashFunction)(key)) % table->size;
	slli t2 t0 2	# multiply location by 4 to account for byte size
	lw t3, 8(s0)	#t3 = table->data (load pointer)
	add t3 t3 t2	#t3 = (t3) data address + location*4
	#save this for later access! t3 is preserved
	lw t4 0(t3)		#load into t4.... t4 = table->data[location]
	sw t4 8(s3)		#newBucket->next = table->data[location]
	sw s2 4(s3)		#newBucket->data = data
	sw s1 0(s3)		# newBucket->key = key
	sw s3 0(t3)		#table->data[location] = newBucket;
	lw t5 0(s0)		#t5 = used
	addi t5 t5 1	#t5+=1
	sw t5 0(s0)		#increment and re-store the "used" variable


	lw s3 16(sp) #for newBucket
	lw s2 12(sp) #for data pointer
	lw s1 8(sp) #for key pointer
	lw s0 4(sp) #for table pointer
	lw ra 0(sp)
	addi sp sp 20
	ret

# void *findData(HashTable *table, void *key);
findData:
	addi sp sp -16
	sw ra 0(sp) #for return address
	sw s0 4(sp) #for table pointer
	sw s1 8(sp) #for key pointer
	sw s2 12(sp) #for lookAt
	mv s0 a0
	mv s1 a1
	mv a0 s1		#set up parameters
	lw t1 0(s0)
	jalr ra 0(t1)	#hashFunction(key)
	sw t0 12(s0)	#t0 = table -> size
	rem t1 a0 t0	#t1 (location)= ((table->hashFunction)(key)) % table->size
	lw t2 4(s0)		#table->data ~get the pointer
	slli t1 t1 2	#location = location*4
	add t2 t1 t2	#get address of data[location]
	lw s2 0(t2)		#lookAt pointer
	#maybe add another lw????

while_start:

	mv a0 s1		#prep argument
	lw a1 0(s2)		#prep argument
	jalr ra 4(s0)	#equalFunction(key, lookAt->key)
	beq s3 x0 continue
	lw a0 4(s2)
	j end				#return if found

continue:
	lw s2 8(s2)		#lookAt = lookAt->next
	bne x0, s2, while_start
	end: 
	lw s2 12(sp) #for lookAt
	lw s1 8(sp) #for key pointer
	lw s0 4(sp) #for table pointer
	lw ra 0(sp)
	addi sp sp 16
	mv a0 x0
	ret