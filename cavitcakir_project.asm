.data
inputFile:       .asciiz "/Users/cavitcakir/asm codes/input.txt"
insertionFile:   .asciiz "/Users/cavitcakir/asm codes/insertion_sort.txt"
selectionFile:   .asciiz "/Users/cavitcakir/asm codes/selection_sort.txt"
endPrompt:       .asciiz "insertion_sort.txt and selection_sort.txt are created!. \nProject Terminating... \n"
startPrompt:     .asciiz "Project started \n"
readbuffer:      .space 4096    # 12 bytes are reserved for each word. -> This able me to traverse the array with (start + i*12) multiplication
                                # So we can at most sort 4096/12 = 341 words.
                                # However, last 12 bytes are reserved for insertion sort's key value.
                                # So, we can at most sort 341-1 = 340 words.

                                # NOTE: the input.txt is expected as there is empty line at the end of the file 
                                #       as the example input.txt that given in project description.
.text
.globl main

#######################################################################################################
# INITIALIZATION STARTS
#######################################################################################################

main:
    li $s7,0                                 # s7 -> 0: Insertion Sort, 1: Selection Sort, 2: Terminate
    la $a0,startPrompt
    li $v0,4
    syscall

    jal OpenFile
    move $s0, $v0                            # s0 -> store file descriptor

    jal CreateArray                          # v0 points starting address of the array of size 4096 byte
    move $s1, $v0                            # s1 -> keeps start of the array pointer
    addi $s6, $s1, 4084                      # set the key pointer location

    jal ReadFile
    move $s2, $v0                            # s2 file has how many char read so far

#######################################################################################################
# INITIALIZATION ENDS
#######################################################################################################

# -----------------------------------------------------------------------------------------------------

#######################################################################################################
# FILE READING & ARRAY FILLING STARTS
#######################################################################################################

Start:
    bnez $s2, FileToArray                    # if file is not empty -> fill the array with the file
    
    move $t1, $s0                            # t1 -> set file desc
    addi $s7, $s7, 2                         # increment sorting mode by 2 to Terminate
    j Exit                                   # Exit


FileToArray:
    li  $t1, 0                               # t1 -> loop counter -> for i in range(buffer_size):
    move $s3, $s1                            # s3 -> is array pointer, initally -> start of the array -> will point end of the data in the array
    li $t6, 0                                # t6 -> word index

    FileToArrayLoop:
        lb $t3, readbuffer($t1)              # t3 -> each char
        
        add $t4, $t6, $s3                    # t4 -> next address of next char in the array           
        sb  $t3,($t4)                        # store current char to [t4]

        beq $t3, 10, NextWordFileToArray     # go next_word if t3 == \n
        addi $t6, $t6, 1                     # array pointer ++

    NextFileToArrayIter:	
        addi $t1, $t1, 1                     # i++
        beq $t1, 4096, EndFileToArrayLoop    # if i used all storage
        bge $t1, $s2, EndFileToArrayLoop     # if i read all the file
        j FileToArrayLoop                    # continue loop

    NextWordFileToArray:
        addi $s3, $s3, 12                    # calculate the address of the starting of the next word
        move $s4, $s3                        # shift array pointer to the starting of the next word
        li $t6, 0                            # set word index to 0
        j NextFileToArrayIter                # go next word

    EndFileToArrayLoop:
        beq $s7, 0, InsertionSort            
        beq $s7, 1, SelectionSort
        j Terminate	

#######################################################################################################
# FILE READING & ARRAY FILLING STARTS
#######################################################################################################

# -----------------------------------------------------------------------------------------------------

#######################################################################################################
# INSERTION SORT STARTS
#######################################################################################################

# ---------
# C++ CODE - https://www.geeksforgeeks.org/insertion-sort/
# ---------
# void insertionSort(int arr[], int n)
# {
#     int i, key, j;
#     for (i = 1; i < n; i++) {
#         key = arr[i];
#         j = i - 1;
#
#         while (j >= 0 && arr[j] > key) {
#             arr[j + 1] = arr[j];
#             j = j - 1;
#         }
#         arr[j + 1] = key;
#     }
# }
# ---------
# MIPS CODE
# ---------
InsertionSort:              
    move $t1, $s1                                           # t1 -> i = 0                                  
    addi $t1, $t1, 12                                       #       i = 1

    InsertionSortForLoop:                                   # for (i = 1; i < n; i++)
        addi $t2, $t1,-12                                   # t2 -> j = i - 1                               
        jal StoreKeyToEnd                                   # key = arr[i]; -> store KEY at the end of the array

        InsertionSortWhileLoop:                             # while (j >= 0 && arr[j] > key)
            blt $t2, $s1, EndInsertionSortWhileLoop         # check if j < 0'th index 
            jal CompareInsertionSort                        # if j>=0 then check arr[j] > key 
            beqz $s4, EndInsertionSortWhileLoop             # s4 -> if arr[j] > key 1, otherwise 0

            jal Shift                                       # arr[j + 1] = arr[j];
            addi $t2, $t2, -12                              # j--
            j InsertionSortWhileLoop

        EndInsertionSortWhileLoop:
            jal InsertKey                                   # arr[j + 1] = key;
            addi $t1, $t1 12                                # i++
            bge $t1, $s3, CreateFileInsertionSort           # if(i >= last address) then the file is sorted.
            j InsertionSortForLoop

StoreKeyToEnd:
    addi $sp, $sp, -4                                       # -> get slot for return address
    sw $ra,0($sp)                                           # -> write return address

    jal StoreAndIncrease                                    # -> store first 4 bytes
    jal StoreAndIncrease                                    # -> store middle 4 bytes 
    jal StoreAndIncrease                                    # -> store last 4 bytes 

    addi $t1, $t1, -12                                      # -> restore t1
    addi $s6, $s6, -12                                      # -> restore s6
    lw $ra,0($sp)                                           # -> restore return adress
    jr $ra

StoreAndIncrease:
    lw $t3, 0($t1)                                          # t3 -> first 4 bytes of i'th word                   
    sw $t3, 0($s6)                                          # stored to the end of the array
    addi $t1, $t1, 4                                        # next 4 bytes
    addi $s6, $s6, 4                                        # next 4 bytes
    jr $ra                                  

Shift:
    lw $t6, 0($t2)                                          # t6 = arr[j]       -> first 4 bytes                                     
    sw $t6, 12($t2)                                         # arr[j + 1] = t6   -> first 4 bytes  

    lw $t6, 4($t2)                                          # t6 = arr[j]       -> middle 4 bytes  
    sw $t6, 16($t2)                                         # arr[j + 1] = t6   -> middle 4 bytes  

    lw $t6, 8($t2)                                          # t6 = arr[j]       -> last 4 bytes  
    sw $t6, 20($t2)                                         # arr[j + 1] = t6   -> last 4 bytes  

    jr $ra

InsertKey:
    lw $t6, 0($s6)                                          # t6 = key           -> first 4 bytes
    sw $t6, 12($t2)                                         # arr[j + 1] = key   -> first 4 bytes  

    lw $t6, 4($s6)                                          # t6 = key           -> middle 4 bytes
    sw $t6, 16($t2)                                         # arr[j + 1] = key   -> middle 4 bytes  

    lw $t6, 8($s6)                                          # t6 = key           -> last 4 bytes
    sw $t6, 20($t2)                                         # arr[j + 1] = key   -> last 4 bytes   

    jr $ra

CompareInsertionSort:                                       # t2 = j        
    li $s4, 0                                               # counter k & return value                        
    CompareLoopInsertionSort:
        add $t6, $s4, $t2                                   # t6 -> j + k                                              
        lb $t7, 0($t6)                                      # t7 -> array[j+k]         

        add $t6, $s4, $s6                                   # t6 -> key + k                    
        lb $t9, 0($t6)                                      # t9 -> array[key+k]      

        bgt $t7, $t9, EndCompareTrue                        # array[j+k] > array[key+k] -> then return s4 true
        bgt $t9, $t7, EndCompareFalse                       # array[key+k] > array[j+k] -> then return s4 false
    
        beq $s4, 12, EndCompareFalse                        # if len(j) == len(key) and all elements are same then return s4 false
        addi $s4, $s4, 1                                    # counter k++
        j CompareLoopInsertionSort

CreateFileInsertionSort:  
    la $a0, insertionFile                                   # a0 -> filename
    li $a1, 1                                               # a1 -> flags
    li $a2, 0 	                                            # a2 -> mode
    li $v0, 13	
    syscall  

    move $t1, $v0                                           # t1 -> file desc
    move $t3, $s1                                           # t3 -> starting of file
    j WriteToFile

#######################################################################################################
# INSERTION SORT ENDS
#######################################################################################################


# -------------------------------------------------------------------------------------------------------


#######################################################################################################
# SELECTION SORT STARTS
#######################################################################################################

# ---------
# C++ CODE - https://www.geeksforgeeks.org/selection-sort/
# ---------
#void selectionSort(int arr[], int n)
# {
#     int i, j, min_idx;
#     // One by one move boundary of unsorted subarray
#     for (i = 0; i < n-1; i++)
#     {
#         // Find the minimum element in unsorted array
#         min_idx = i;
#         for (j = i+1; j < n; j++)
#           if (arr[j] < arr[min_idx])
#             min_idx = j;
#         // Swap the found minimum element with the first element
#         swap(&arr[min_idx], &arr[i]);
#     }
# }
# ---------
# MIPS CODE
# ---------
SelectionSort:
    move $t1, $s1                                           # t1 -> i = 0    
    SelectionSortOuterForLoop:                              # for (i = 0; i < n-1; i++)
        move $t2, $t1                                       # t2 -> min_idx = i   
        addi $t3, $t1, 12                                   # t3 -> j = i + 1                 
        SelectionSortInnerForLoop:                          # for (j = i+1; j < n; j++)
            bge $t3, $s3, EndSelectionSortInnerForLoop      # if j >= n go end of inner
            jal CompareSelectionSort                        # if j < n then check arr[j] < arr[min_idx]
            beq $s4, 1, SkipIf                              # if (arr[j] >= arr[min_idx]) then go Skip
                move $t2, $t3                               # min_idx = j;
            SkipIf:
                addi $t3, $t3, 12                           # j++
                j SelectionSortInnerForLoop

        EndSelectionSortInnerForLoop:
            jal SwapSelectionSort                           # swap(&arr[min_idx], &arr[i]);
            # addi $t1, $t1 12                              # i++ 
            bge $t1, $s3, CreateFileSelectionSort           # if(i >= last address) then the file is sorted.
            j SelectionSortOuterForLoop

CompareSelectionSort:                                       # j -> t3 , min -> t2
    li $s4, 0 # counter                                     # counter k & return value                              
    LoopSelectionSort:
        add $t6, $s4, $t3                                   # t6 -> j + k
        lb $t7, 0($t6)                                      # t7 -> array[j+k]   

        add $t6, $s4, $t2                                   # t6 -> min_id + k
        lb $t9, 0($t6)                                      # t9 -> array[min_id+k]

        bgt $t7, $t9, EndCompareTrue                        # array[j+k] > array[min_id+k] -> then return s4 true
        bgt $t9, $t7, EndCompareFalse                       # array[min_id+k] > array[j+k] -> then return s4 false

        beq $s4, 12, EndCompareFalse                        # if len(j) == len(min_id) and all elements are same then return s4 false
        addi $s4, $s4, 1                                    # counter k++
        j LoopSelectionSort

SwapSelectionSort:
    addi $sp, $sp, -4		                                # -> get slot for return address
    sw $ra,0($sp)                                           # -> write return address

    jal SwapAndIncrease                                     # swap(&arr[min_idx], &arr[i]); first 4 bytes 
    jal SwapAndIncrease                                     # swap(&arr[min_idx], &arr[i]); middle 4 bytes 
    jal SwapAndIncrease                                     # swap(&arr[min_idx], &arr[i]); last 4 bytes 

    addi $t2, $t2, -12                                      # set t2 back.
    lw $ra,0($sp)                                           # -> restore return adress
    jr $ra

SwapAndIncrease:
    lw $t4, 0($t1)                                          
    lw $t5, 0($t2)                                                                                          
    sw $t5, 0($t1)                                         
    sw $t4, 0($t2)                                          
    
    addi $t1, $t1, 4                                        # next 4 bytes
    addi $t2, $t2, 4                                        # next 4 bytes                                       

    jr $ra

CreateFileSelectionSort:
    la $a0, selectionFile                                   # a0 -> filename
    li $a1, 1                                               # a1 -> flags
    li $a2, 0 	                                            # a2 -> mode
    li $v0, 13	
    syscall  

    move $t1, $v0                                           # t1 -> file desc
    move $t3, $s1                                           # t3 -> starting of file

    j WriteToFile

#######################################################################################################
# SELECTION SORT ENDS
#######################################################################################################


# -------------------------------------------------------------------------------------------------------


#######################################################################################################
# HELPERS STARTS
#######################################################################################################

OpenFile:
    la $a0, inputFile                                       # a0 -> filename
    li $a1, 0                                               # a1 -> flags
    li $a2, 0                                               # a2 -> mode
    li $v0, 13
    syscall
    jr $ra

CreateArray:
    li $a0, 4096                                            # store whole data, condition -> data < 4096 bytes
    li $v0, 9
    syscall
    jr $ra

ReadFile:					
    move $a0, $s0                                           # a0 -> file desc
    la $a1, readbuffer                                      # a1 -> buffer
    li $a2, 4096                                            # a2 -> buffer size
    li $v0, 14
    syscall	
    jr $ra

EndCompareTrue:
    li $s4, 1
    jr $ra

EndCompareFalse:
    li $s4, 0
    jr $ra

WriteToFile:
        jal StringLength                                    # calculates current string length and puts in s5
        move $a0, $t1                                       # a0 -> file desc
        move $a1, $t3                                       # a1 -> address of output buffer
        move $a2, $s5                                       # a2 -> s5 -> number of characters to write
        li   $v0, 15
        syscall

        addi $t3, $t3, 12                                   # next word
        
        bge $t3, $s3, Exit                                  # if all the words are written then exit
        
        j WriteToFile

StringLength:
    li $s5, 0                                               # s5 -> total count
    move $t5, $t3                                           # t5 -> pointer to the the word
    LoopStringLength:
        lb $t7, 0($t5)                                      # t7 -> next character
        beqz $t7, ExitStringLength                          # check for the null character
        beq $t7, 10, ExitStringLength                       # check for \n
        addi $t5, $t5, 1                                    # increment the string pointer
        addi $s5, $s5, 1                                    # increment the total count
        j LoopStringLength
    ExitStringLength:
        beq $s5, 0, SkipLast                                # if line is empty then skip incrementing
        addi $s5, $s5, 1                                    # increment the count for the \n at the end of the word
        SkipLast:
            jr $ra 

#######################################################################################################
# HELPERS ENDS
#######################################################################################################


# -------------------------------------------------------------------------------------------------------


#######################################################################################################
# EXIT - TERMINATE
#######################################################################################################

Exit: 
    li   $v0, 16                                            # system call for close file
    move $a0, $t1                                           # file descriptor to close
    syscall                                                 # close the file

    addi $s7, $s7, 1                                        # increment sorting mode by 1
    blt $s7, 2, Start                                       # if we did not complete the selection sort then go to start

Terminate:
    la $a0, endPrompt
    li $v0, 4
    syscall	
    li $v0, 10
    syscall
