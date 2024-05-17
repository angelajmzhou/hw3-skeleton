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
#                           int (*equalFunction)(void *, void *));
createHashTable:
	addi sp sp -24
	sw ra 0(sp) 
	sw s0 4(sp)		 #store size
	sw s1 8(sp) 	#store hashFunction pointer
	sw s2 12(sp) 	#store equalFunction pointer
	sw s3 16(sp)	 #for the newTable
	sw s4 20(sp) 	#for the hashtable pointer
	mv s0 a0
	mv s1 a1
	mv s2 a2		#change from t0 to s0 so it doesn't get trashed....
	li a0 20 		#sizeofHashtable
	j malloc 		#malloc
	mv s3 a0 		#HashTable *newTable = malloc(sizeof(HashTable))
	sw s0 12(s3)	#newTable -> size = size
	sw x0 16(s3)	#newTable -> used = 0
	li t2 12
	mul t2 t2 s0
	mv a0 t2		#argument is hashbucket * size
	j malloc		#malloc HashBucket
	sw a0 8(s4)		#newTable->data
	mv t0 x0			#i=0
	loop_start: 
	lw t2 8(s4) 		#load newTable -> data (gets data pointer)
	slli t3 t0 2 		#"multiply" by 4 for storage, store in t3
	add t3 t2 t3 		#add the offset
	mv t3 x0		#store null in the data 
	addi t0 t0 1 		#increment
	bge t0 s0 loop_start 	#loop condition
	sw s1 0(t1)		#newTable->hashFunction = hashFunction;
  	sw s2 4(t1)		#newTable->equalFunction = equalFunction;
	lw s4 20(sp)	 #for the hashtable pointer
	lw s3 16(sp) 	#restore the newTable
	lw s2 12(sp)	 #restore equalFunction pointer
	lw s1 8(sp) 	#restore hashFunction pointer
	lw s0 4(sp) 	#restore size
	lw ra 0(sp)
	addi sp sp 24
	ret

# void insertData(HashTable *table, void *key, void *data);
insertData:
	addi sp sp -20
	sw ra 0(sp) #for return address
	sw s0 4(sp) #for table pointer
	sw s1 8(sp) #for key pointer
	sw s2 12(sp) #for data pointer
	sw s3 16(sp) #for newBucket
	mv s0 a0
	mv s1 a1
	mv s2 a2
	li a0 12
	j malloc
	mv s3 a0 		#store the returned malloced space
					#ie: *newBucket (s3) = malloc...
	lw t1 12(s0) 	#t2 = table -> size
	mv a0 s1 		#set up parameter of function call
	jalr ra 0(s1)	#run hashFunction on key
	mv t5 a0		#t5 = hashFunction(key)
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
	mv s2 a2
	mv a0 s1		#set up parameters
	jalr ra 0(s0)	#hashFunction(key)
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
	ret				#return if found

continue:
	lw s2 8(s2)		#lookAt = lookAt->next
	bne x0, s2, while_start
	lw s2 12(sp) #for lookAt
	lw s1 8(sp) #for key pointer
	lw s0 4(sp) #for table pointer
	lw ra 0(sp)
	addi sp sp 16
	mv a0 x0
	ret
