#####################################################################

# Bitmap Display Configuration:
# - Unit width in pixels: 8					     
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#

#####################################################################


.data
	displayAddress:	.word	0x10008000
	backgroundColor: .word 0xfaeecd
	doodleColor:  .word 0xff0800
	platformColor: .word 0x53c4e0
	
	scoreColor: .word 0x92e09c
	
	messageColor: .word 0xeb66ed
	byeColor: .word 0x3d84ba
	
	platfromArray: .space 12
	doodlerPosition: .word 3660 
	doodlerDirection: .word 0 # doodlerDirection 0 when doodler moving down, 1 when it is moving up
	
	platformSize: .word 10

	
	screenNumber: .word 0
	scoreOffset: .word 0
	
	messageCounter: 1 # 0 for message 1 for no message

	# expenable: Set before each function call
	
	# $t0 : display address, 
	# $t1 : main point,
	# $t6: screenNumber t7: midpoint of the doodler
	# $t2 : size of platform (expendable: used for drawing platform), 
	# $t3 : color loaded(expendable: changed only when drawing), $t5 row (expendable: used to set row), $t4 col (expendable: used to set col)
	
	#$s0 platform 0(lowest), $s1 platform 1(middle), $s2 platform 2(highest)
.text   

main:

startScreen: ## Bottom and middle platforms set for screen zero

       jal drawBackground
       li $t5, 30
       li $t4, 15
       jal getPoint #main point at t1
       move $s0, $t1 #save the value to push to stack later: this is the lowest platform
       
       jal drawPlatforms # draw first platform
       
       li $t5, 20
       li $t4, 10
       jal getPoint #main point at t1 
       move $s1, $t1 #save the value to push to stack later: this is the middle platform
      
       jal drawPlatforms # draw second platform
       
       jal generateRandomPoint #randomly generate the top most platform around row 0 - 10
       jal getPoint  
       move $s2, $t1 #save the value to push to stack later: this is the highest platform
       
       jal drawPlatforms # draw third platform
       
       addi $t7, $zero, 0
       sw $s0, platfromArray($t7)
       addi $t7, $t7, 4
       sw $s1, platfromArray($t7)
       addi $t7, $t7, 4
       sw $s2, platfromArray($t7)
     
   
       #Placing doodler on lowest platfrom to start off
       jal drawDoodler
      
                                        
   
waitForInput:
       lw, $t5, 0xffff0000 # check for feedback
       bnez $t5, playGameInitializer
       j waitForInput             

playGame: 
       lw, $t5, 0xffff0000
       beqz, $t5, continueGame
       
playGameInitializer:
       lw, $t5, 0xffff0004 # check what movement is made 
       beq $t5, 0x6b, moveRight                                                                      
       beq $t5, 0x6a, moveLeft                                   
                                                                                                                                       
continueGame: 
       jal checkGameContinues 
       jal checkScore  
       j displayScore

scoreMaker:
	j checkForEncouragement

return:                  
       lw $t4, doodlerDirection
       beq $t4, 1, makeDoodleFly
       beq $t4, 0, makeDoodleFall

       j playGame    
        
makeDoodleFly: # doodle moves 1 row up each repaint
        jal eraseDoodler
        lw $t7, doodlerPosition
        addi, $t7, $t7, -128
        sw $t7, doodlerPosition
        jal drawDoodler
                 
        j checkMaxHeight  
returnMaxHeight:       
        jal Sleep
        jal sound

        j playGame 
                                                                                                                        
makeDoodleFall: # doodle moves 1 row down each repaint
        jal checkForPlatform

        jal eraseDoodler
        lw $t7, doodlerPosition
        addi, $t7, $t7, 128
        sw $t7, doodlerPosition
        jal drawDoodler 
        
        jal Sleep                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
        j playGame                                                
       
moveRight:
 	jal eraseDoodler
 	lw $t7, doodlerPosition
        addi, $t7, $t7, 4
        sw $t7, doodlerPosition
 	jal drawDoodler
 	jal Sleep
 	
 	j continueGame

 moveLeft: 
 	jal eraseDoodler
 	lw $t7, doodlerPosition
        addi, $t7, $t7, -4
        sw $t7, doodlerPosition
        jal drawDoodler
        jal Sleep
        
        j continueGame

        
checkScore:
	lw $t7, doodlerPosition                                                                                                                                                                                                                                              
        addi $s3, $t7, 260 #space below right leg
        addi $s4, $t7, 252 #space below left leg
	
	li $t4, 4
	lw, $t3, platfromArray($t4)
	
	
	li $t4, 4
	lw $t5, platformSize
	mult $t5, $t4
	mflo $t5
	
	li $t4, 0
	add $t4, $t3, $t5 #Max lenght

	checkTillPlatformOver:
        
        	beq $t3, $t4, returncheckScore
		beq $s3, $t3, updateScore   
		beq $s4, $t3, updateScore

        	addi, $t3, $t3, 4
        	j checkTillPlatformOver

	updateScore:
        	lw $t2, screenNumber
        	addi, $t2, $t2, 1
        	sw $t2, screenNumber
        	
        	
       returncheckScore:	
        	jr $ra
 	                                                                                                                                                                                                                                                                                                                                                                        
checkForPlatform:       
        
        lw $t7, doodlerPosition                                                                                                                                                                                                                                              
        addi $s3, $t7, 260 #space below right leg
        addi $s4, $t7, 252 #space below left leg
     
        lw $t3, platformColor
        
        lw $t0, displayAddress
        add $t0, $t0, $s3 # s3 has location below right leg
        lw $s5, 0($t0)  # s5 has color below right leg
        
        lw $t0, displayAddress
        add $t0, $t0, $s4 # s4 has location below left leg
        lw $s6, 0($t0)  # s6 color below left leg
        
        #if the color is a platform then doodle jumps
        beq $s5, $t3, setDoodlerDirectionto1  
        beq $s6, $t3, setDoodlerDirectionto1
        
        
        j setDoodlerDirectionto0
        
returnback:
        jr $ra     
      
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
setDoodlerDirectionto1:
	li $t5, 1
	sw $t5, doodlerDirection

	j returnback

setDoodlerDirectionto0:
	li $t5, 0
	sw $t5, doodlerDirection
	j returnback
	   
checkGameContinues:
        lw $t7, doodlerPosition
	bge $t7, 3968, bye
        j returnback
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
checkMaxHeight:
        #lw $t7, doodlerPosition
	#bgt $t7, 1024, dontsetDirection
	lw $t7, doodlerPosition
        li $t4, 4
        lw $t5, platfromArray($t4)
        addi $t5, $t5, -512
	bgt $t7, $t5, dontsetDirection
	jal setDoodlerDirectionto0
dontsetDirection:
	lw $t3, screenNumber
        lw $t6, scoreOffset
        beq $t6, $t3, noNewScore 
        addi $t6, $t6, 1
        sw $t6, scoreOffset
        j movePlatforms
     
noNewScore:
	
        j returnMaxHeight


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
drawDoodler:   
	lw $t3, doodleColor
	lw $t2, platformColor
	j getshifts
	
eraseDoodler:   
	lw $t3, backgroundColor
	lw $t2, platformColor
        j getshifts


getshifts:

	lw, $t7, doodlerPosition	  
	addi, $s3, $t7, -128 # head
	addi, $s4, $t7, 4 # middle right
	addi, $s5, $t7, -4 # middle left
	addi, $s6, $t7, 124 # base left
	addi, $s7, $t7, 132 #base right
	
	#Middle Coloring
	lw $t0, displayAddress
	add $t0, $t0, $t7 # midpoint color
	lw $t4, 0($t0)
	beq $t4, $t2, SkipMiddle
	sw $t3, 0($t0)
	
SkipMiddle:
        #Head Coloring
	lw $t0, displayAddress
	add $t0, $t0, $s3 
	lw $t4, 0($t0)
	beq $t4, $t2, SkipHead
	sw $t3, 0($t0)
	
SkipHead:
        #Middle Right Coloring
	lw $t0, displayAddress
	add $t0, $t0, $s4
	lw $t4, 0($t0)
	beq $t4, $t2, SkipMiddleRight
	sw $t3, 0($t0)

SkipMiddleRight:
        # Middle Left Coloring
        lw $t0, displayAddress
	add $t0, $t0, $s5 
	lw $t4, 0($t0)
	beq $t4, $t2, SkipMiddleLeft
	sw $t3, 0($t0)

SkipMiddleLeft:
        lw $t0, displayAddress
	add $t0, $t0, $s6 
	lw $t4, 0($t0)
	beq $t4, $t2, SkipBaseLeft
	sw $t3, 0($t0)

SkipBaseLeft:
        lw $t0, displayAddress
	add $t0, $t0, $s7 
	lw $t4, 0($t0)
	beq $t4, $t2, SkipBaseRight
	sw $t3, 0($t0)

SkipBaseRight:		
	jr $ra

 

movePlatforms: #Platforms move 5 rows down each repaint
 
removeLowestPlatfrom: #erases lowest platfrom
 	lw, $t1, platfromArray($zero)
 	jal erasePlatforms
moveUpper: #erases the middle platfrom
 	li $t2, 4
 	#new code
 	lw $t5, platfromArray($t2)
 	li $t2, 8
 	lw $t6, platfromArray($t2)
 	j changeMiddlePlatfromPosition
 	
 	
changeMiddlePlatfromPosition: #gets the offset to make the middle platfrom into the lowest platfrom
 
 	li $t2, 3968
 	bge $t5, $t2, drawNewPlatfrom #switched
 	#erasing middle platfrom
 	move $t1, $t5
 	jal erasePlatforms
 	move $t1, $t6
 	jal erasePlatforms
 	add $t5, $t5, 128
 	move $t1, $t5
 	jal drawPlatforms
 	add $t6, $t6, 128
 	move $t1, $t6
 	jal drawPlatforms
 	jal Sleep
 	j changeMiddlePlatfromPosition
 	
drawNewPlatfrom: #draws new platfroms for the middle one and the highest one 
 	sw $t5, platfromArray($zero)
 	li $t4, 4
 	sw $t6, platfromArray($t4)
 	j generatingNewRandomPlatfrom
 	
generatingNewRandomPlatfrom:
	#generating new topmost platfrom
	jal Sleep
	jal generateRandomPoint
	jal getPoint     

	jal drawPlatforms
	li $t2, 8
	sw $t1, platfromArray($t2)
 	jal Sleep
 	j noNewScore
 	



drawBackground:
       lw $t0, displayAddress	# $t0 stores the base address for display
       lw $t3, backgroundColor	# $t1 stores the beige color
       li $t4, 4096
       li $t5, 0
STARTLOOP: 
      beq $t5, $t4, ENDLOOP
      sw $t3, 0($t0)
      addi $t0, $t0, 4
      add $t5, $t5, 4
      j STARTLOOP
      jr $ra
ENDLOOP: jr $ra 




generateRandomPoint: #save random row in t5 and random col in t4
getRandomRow:  #t5 is row coordinate
        li $v0, 42  # 42 is system call code to generate random int
        li $a1, 5 # $a1 is where you set the upper bound: 10 in our case for the top half of the screen
        syscall    # your generated number will be at $a0
        move $t5, $a0
        blt $t5, 2, getRandomRow # lowerbound 4
     
        
getRandomCol:  #t4 is colm coordinate      
        li $v0, 42  # 42 is system call code to generate random int
        li $a1, 20 # $a1 is where you set the upper bound
        syscall     # your generated number will be at $a0
        move $t4, $a0     
        
        jr $ra   
        
getPoint: #loads main coordinate to $t1, load starting row in t5 and col in t4  
	li $t1, 32
	mult $t1, $t5
	mflo $t1
	add $t1, $t1, $t4
	li $t4, 4
	mult $t1, $t4
	mflo $t1
        jr $ra


drawPlatforms:   # Load size of platform in $t2
       
	lw $t0, displayAddress
	add $t0, $t0, $t1 #$t1 is main coordinate
	lw $t2, platformSize
	lw $t3, platformColor
	
	j PlatformLoop

erasePlatforms:    # Load size of platform in $t2
	lw $t0, displayAddress
	add $t0, $t0, $t1 #$t1 is main coordinate
	lw $t2, platformSize
	lw $t3, backgroundColor
	
	
	j PlatformLoop


PlatformLoop:
        
        lw $t7, doodleColor
	beqz $t2, EndDraw
	
	lw $t4, 0($t0)
	beq $t7, $t4, skip
	
       	sw $t3, 0($t0)
       	
skip:
        addi $t2, $t2, -1
       	addi $t0, $t0, 4
       	
       	j PlatformLoop    		       		
       		
EndDraw:	
	jr $ra	
	



checkForEncouragement:
	
timeForDynamicMessaging:
	lw $t7, screenNumber
	beq $t7, 10, sayNice
	beq $t7, 11, sayNice
	beq $t7, 12, sayNice
	beq $t7, 13, sayNice
	beq $t7, 14, sayNice
	beq $t7, 15, timeForErasingMessaging
	
	beq $t7, 20, sayCool
	beq $t7, 21, sayCool
	beq $t7, 22, sayCool
	beq $t7, 23, sayCool
	beq $t7, 24, sayCool
	beq $t7, 25, timeForErasingMessaging
	beq $t7, 30, sayWow
	beq $t7, 31, sayWow
	beq $t7, 32, sayWow
	beq $t7, 33, sayWow
	beq $t7, 34, sayWow
	beq $t7, 35, timeForErasingMessaging
	
	beq $t7, 50, sayNice
	beq $t7, 51, sayNice
	beq $t7, 52, sayNice
	beq $t7, 53, sayNice
	beq $t7, 54, sayNice
	beq $t7, 55, timeForErasingMessaging
	
	beq $t7, 60, sayWow
	beq $t7, 61, sayWow
	beq $t7, 62, sayWow
	beq $t7, 63, sayWow
	beq $t7, 64, sayWow
	beq $t7, 65, timeForErasingMessaging
	
	beq $t7, 80, sayCool
	beq $t7, 81, sayCool
	beq $t7, 82, sayCool
	beq $t7, 83, sayCool
	beq $t7, 84, sayCool
	beq $t7, 85, timeForErasingMessaging
	
	beq $t7, 90, sayWow
	beq $t7, 91, sayWow
	beq $t7, 92, sayWow
	beq $t7, 93, sayWow
	beq $t7, 94, sayWow
	beq $t7, 95, timeForErasingMessaging
	
	
	j return
	
	
	
timeForErasingMessaging:

	j dontgiveAmessage
	j return
	

					
sayNice:  	
		lw, $t1, messageColor	
		jal nice
		li $t8, 0
		sw $t8, messageCounter
		j return

sayWow:  	
		lw, $t1, messageColor	
		jal wow
		li $t8, 0
		sw $t8, messageCounter
		j return

sayCool:  	
		lw, $t1, messageColor	
		jal cool
		li $t8, 0
		sw $t8, messageCounter
		j return
		

dontgiveAmessage:



	li, $t1, 68

	li $t4, 15
	sw $t4, platformSize
	jal erasePlatforms
	
	li $t1, 196
	jal erasePlatforms
	
	li $t1, 324
	jal erasePlatforms
	
        li $t1, 452
	jal erasePlatforms
	
	li $t1, 580
	jal erasePlatforms
	
	li $t4, 10
	sw $t4, platformSize

	li $t8, 1
	sw $t8, messageCounter
	j return
	


#####################
#wow! screen
#####################		
			
nice:
        # LOAD COLOR IN T1 PLS						
        lw $t0, displayAddress
	addi $t0, $t0, 80
	addi $t0, $t0, 128
	sw $t1, 0($t0)
	add $t0, $t0, 128
	sw $t1, 0($t0)
	add, $t0, $t0, 128
	sw $t1, 0($t0)
	add, $t0, $t0, 4
	add, $t0, $t0, -128
	sw $t1, 0($t0)
	add, $t0, $t0, 4
	add, $t0, $t0, 128
	sw $t1, 0($t0)
	add, $t0, $t0, 4
	add, $t0, $t0, 4																																																																								
	addi $t0, $t0, -128
	add $t0, $t0, -128
	sw $t1, 0($t0)
	add, $t0, $t0, 128
	add, $t0, $t0, 128	
	sw $t1, 0($t0)	
	
	add, $t0, $t0, 4
	add, $t0, $t0, 4
	add, $t0, $t0, -128	
	sw $t1, 0($t0)	
	add, $t0, $t0, -128	
	sw $t1, 0($t0)	
        add, $t0, $t0, 128
        add, $t0, $t0, 128
        sw $t1, 0($t0)
        add, $t0, $t0, 4
        sw $t1, 0($t0)	
         add, $t0, $t0, -128
        add, $t0, $t0, -128
	sw $t1, 0($t0)
	
	add, $t0, $t0, 4
	add, $t0, $t0, 4
	add, $t0, $t0, 128
	sw $t1, 0($t0)
        add, $t0, $t0, 128
        sw $t1, 0($t0)
        add, $t0, $t0, -128
 
        add, $t0, $t0, -128
        sw $t1, 0($t0)
        add, $t0, $t0, 4
        add, $t0, $t0, -128
        sw $t1, 0($t0)
     	add, $t0, $t0, 128
     	add, $t0, $t0, 128
        sw $t1, 0($t0)
        add, $t0, $t0, 128
     	add, $t0, $t0, 128
	sw $t1, 0($t0)
							
	jr $ra							

#####################
#cool screen
#####################												
        
 cool:       
      
        lw $t0, displayAddress
	
	addi $t0, $t0, 80
	addi $t0, $t0, 128
	sw $t1, 0($t0)
	add $t0, $t0, 128
	sw $t1, 0($t0)
	add, $t0, $t0, 128
	sw $t1, 0($t0)
	add, $t0, $t0, 4
	add, $t0, $t0, -128
	add, $t0, $t0, -128
	sw $t1, 0($t0)
	add, $t0, $t0, 4
	add, $t0, $t0, 128
	add, $t0, $t0, 128
	add, $t0, $t0, -4
	sw $t1, 0($t0)
	
	add, $t0, $t0, 4
	add, $t0, $t0, 4
	
	add, $t0, $t0, -128
	sw $t1, 0($t0)
	add, $t0, $t0, -128
	sw $t1, 0($t0)
	add, $t0, $t0, 128
	add, $t0, $t0, 128
	sw $t1, 0($t0)
	add, $t0, $t0, 4
	sw $t1, 0($t0)
	add, $t0, $t0, -128
	add, $t0, $t0, -128
	sw $t1, 0($t0)
	add, $t0, $t0, 4
	add, $t0, $t0, 128
	sw $t1, 0($t0)
	add, $t0, $t0, 128
	sw $t1, 0($t0)
	add, $t0, $t0, -128
	add, $t0, $t0, -128
	sw $t1, 0($t0)
	
	add, $t0, $t0, 4
	add, $t0, $t0, 4
	
	add, $t0, $t0, 128
	sw $t1, 0($t0)
	add, $t0, $t0, 128
	sw $t1, 0($t0)
	add, $t0, $t0, -128
	add, $t0, $t0, -128
	sw $t1, 0($t0)
	add, $t0, $t0, 4
	sw $t1, 0($t0)
	add, $t0, $t0, 4
	sw $t1, 0($t0)
	add, $t0, $t0, 128
	sw $t1, 0($t0)
	add, $t0, $t0, 128
	sw $t1, 0($t0)
	add, $t0, $t0, -4
	sw $t1, 0($t0)
	
	add, $t0, $t0, 4
	add, $t0, $t0, 4
	add, $t0, $t0, 4
	add, $t0, $t0, -128
	sw $t1, 0($t0)
	add, $t0, $t0, -128
	sw $t1, 0($t0)	
	add, $t0, $t0, 128
	add, $t0, $t0, 128			
	sw $t1, 0($t0)									
																	
	jr $ra			
								

												
#####################
#wow screen
#####################													
																
wow: 	
	lw $t0, displayAddress
	addi $t0, $t0, 68
	addi $t0, $t0, 128																								
	
	sw $t1, 0($t0)
	add $t0, $t0, 128
	sw $t1, 0($t0)	
	add $t0, $t0, 128
	sw $t1, 0($t0)	
	add $t0, $t0, 4
	sw $t1, 0($t0)
	add $t0, $t0, 4
	sw $t1, 0($t0)	
	add $t0, $t0, -128
	sw $t1, 0($t0)	
	add $t0, $t0, 128
	add $t0, $t0, 4
	sw $t1, 0($t0)
	add $t0, $t0, 4
	sw $t1, 0($t0)
	add $t0, $t0, -128
	sw $t1, 0($t0)	
	add $t0, $t0, -128
	sw $t1, 0($t0)
	
	add $t0, $t0, 4
	add $t0, $t0, 4
	sw $t1, 0($t0)
	add $t0, $t0, 128
	sw $t1, 0($t0)
	add $t0, $t0, 128
	sw $t1, 0($t0)
	add $t0, $t0, 4	
	sw $t1, 0($t0)
	add $t0, $t0, 4	
	sw $t1, 0($t0)
	add $t0, $t0, -128
	sw $t1, 0($t0)
	add $t0, $t0, -128
	sw $t1, 0($t0)
	add $t0, $t0, -4
	sw $t1, 0($t0)	
	
	add $t0, $t0, 4
	add $t0, $t0, 4	
	add $t0, $t0, 4
					
	sw $t1, 0($t0)
	add $t0, $t0, 128
	sw $t1, 0($t0)	
	add $t0, $t0, 128
	sw $t1, 0($t0)	
	add $t0, $t0, 4
	sw $t1, 0($t0)
	add $t0, $t0, 4
	sw $t1, 0($t0)	
	add $t0, $t0, -128
	sw $t1, 0($t0)	
	add $t0, $t0, 128
	add $t0, $t0, 4
	sw $t1, 0($t0)
	add $t0, $t0, 4
	sw $t1, 0($t0)
	add $t0, $t0, -128
	sw $t1, 0($t0)	
	add $t0, $t0, -128
	sw $t1, 0($t0)
	
	jr $ra	


	
###################
#working on sound
###################
sound:
		# play a sound
	li $a0, 50		# Make the sound when a point is scored
	li $a1, 100 #duration
	li $a2, 67 #instrument
	li $a3, 127 #volume
	li $v0, 31
	syscall
	jr $ra
	
																						
#####################
#bye screen
#####################
bye:
	lw $t4, byeColor
	
drawB:
	lw $t0, displayAddress
	add $t0, $t0, 2468
	sw, $t4, 0($t0)
	addi $t0, $t0, -128
	sw, $t4, 0($t0)
	addi $t0, $t0, -128
	sw, $t4, 0($t0)
	addi $t0, $t0, -128
	sw, $t4, 0($t0)
	addi $t0, $t0, -128
	sw, $t4, 0($t0)
	addi $t0, $t0, -128
	sw, $t4, 0($t0)
	addi $t0, $t0, -128
	sw, $t4, 0($t0)
	
	lw $t0, displayAddress
	add $t0, $t0, 2468
	add $t0, $t0, 4
	sw, $t4, 0($t0)
	add $t0, $t0, 4
	sw, $t4, 0($t0)
	add $t0, $t0, 4
	sw, $t4, 0($t0)
	
	addi $t0, $t0, -128
	sw, $t4, 0($t0)
	addi $t0, $t0, -128
	sw, $t4, 0($t0)
	
	
	addi $t0, $t0, -4
	sw, $t4, 0($t0)
	addi $t0, $t0, -4
	sw, $t4, 0($t0)
	addi $t0, $t0, -4
	sw, $t4, 0($t0)
	
drawY:
	lw $t0, displayAddress
	add $t0, $t0, 2488
	sw, $t4, 0($t0)
	
	addi $t0, $t0, -128
	sw, $t4, 0($t0)
	addi $t0, $t0, -128
	sw, $t4, 0($t0)
	
	lw $t0, displayAddress
	add $t0, $t0, 2488
	add $t0, $t0, 4
	sw, $t4, 0($t0)
	add $t0, $t0, 4
	sw, $t4, 0($t0)
	add $t0, $t0, 4
	sw, $t4, 0($t0)
	
	addi $t0, $t0, -128
	sw, $t4, 0($t0)
	addi $t0, $t0, -128
	sw, $t4, 0($t0)
	
	add $t0, $t0, 128
	sw, $t4, 0($t0)
	add $t0, $t0, 128
	sw, $t4, 0($t0)
	add $t0, $t0, 128
	sw, $t4, 0($t0)
	add $t0, $t0, 128
	sw, $t4, 0($t0)
	
	addi $t0, $t0, -4
	sw, $t4, 0($t0)
	addi $t0, $t0, -4
	sw, $t4, 0($t0)
	addi $t0, $t0, -4
	sw, $t4, 0($t0)
	
drawe:
	lw $t0, displayAddress
	add $t0, $t0, 2508
	sw, $t4, 0($t0)
	addi $t0, $t0, -128
	sw, $t4, 0($t0)
	addi $t0, $t0, -128
	sw, $t4, 0($t0)
	addi $t0, $t0, -128
	sw, $t4, 0($t0)
	
	move $t2, $t0
	add $t0, $t0, 4
	sw, $t4, 0($t0)
	add $t0, $t0, 4
	sw, $t4, 0($t0)
	add $t0, $t0, 4
	sw, $t4, 0($t0)
	
	move $t0, $t2
	addi $t0, $t0, -128
	sw, $t4, 0($t0)
	addi $t0, $t0, -128
	sw, $t4, 0($t0)
	addi $t0, $t0, -128
	sw, $t4, 0($t0)
	
	add $t0, $t0, 4
	sw, $t4, 0($t0)
	add $t0, $t0, 4
	sw, $t4, 0($t0)
	add $t0, $t0, 4
	sw, $t4, 0($t0)
	
	lw $t0, displayAddress
	add $t0, $t0, 2508
	add $t0, $t0, 4
	sw, $t4, 0($t0)
	add $t0, $t0, 4
	sw, $t4, 0($t0)
	add $t0, $t0, 4
	sw, $t4, 0($t0)
	
drawExclamation:
	lw $t0, displayAddress
	add $t0, $t0, 2528
	sw, $t4, 0($t0)
	
	addi, $t0, $t0, -128
	addi, $t0, $t0, -128
	sw, $t4, 0($t0)
	addi, $t0, $t0, -128
	sw, $t4, 0($t0)
	addi, $t0, $t0, -128
	sw, $t4, 0($t0)
	addi, $t0, $t0, -128
	sw, $t4, 0($t0)
	addi, $t0, $t0, -128
	sw, $t4, 0($t0)
	
	j Exit

	
##########
#drawing score numbers
##########    
#drawScore:
#	lw $t1, scoreColor
#	li $t9, 0
#	jal drawTwo
#	li $t9, 20 # +20 each time
#	jal drawZero
#	li $t9, 40
#	jal drawZero
#	j Exit
	
	
	
	
drawZero:
	lw $t0, displayAddress
	add $t0, $t0, $t9
	sw $t1, 0($t0)
	add $t0, $t0, 128
	sw $t1, 0($t0)
	add, $t0, $t0, 128
	sw $t1, 0($t0)
	add, $t0, $t0, 128
	sw $t1, 0($t0)
	add, $t0, $t0, 128
	sw $t1, 0($t0)
	
	add $t0, $t0, 4
	sw $t1, 0($t0)
	add $t0, $t0, 4
	sw $t1, 0($t0)
	
	addi $t0, $t0, -128
	sw $t1, 0($t0)
	addi $t0, $t0, -128
	sw $t1, 0($t0)
	addi, $t0, $t0, -128
	sw $t1, 0($t0)
	addi, $t0, $t0, -128
	sw $t1, 0($t0)
	
	addi $t0, $t0, -4
	sw $t1, 0($t0)
	addi $t0, $t0, -4
	sw $t1, 0($t0)
	                  	
	jr $ra  
	
drawOne:
	lw $t0, displayAddress
	add $t0, $t0, $t9 #add offset
	sw $t1, 0($t0)
	
	add $t0, $t0, 128
	sw $t1, 0($t0)
	add $t0, $t0, 128
	sw $t1, 0($t0)
	add, $t0, $t0, 128
	sw $t1, 0($t0)
	add, $t0, $t0, 128
	sw $t1, 0($t0)
	
	jr $ra 
	
drawTwo:
	lw $t0, displayAddress
	add $t0, $t0, $t9 #add offset
	add $t0, $t0, 128
	sw $t1, 0($t0)
	add $t0, $t0, 4
	addi $t0, $t0, -128
	sw $t1, 0($t0)
	add $t0, $t0, 4
	sw $t1, 0($t0)
	add $t0, $t0, 128
	add $t0, $t0, 4
	sw $t1, 0($t0)
	add $t0, $t0, 128
	addi $t0, $t0, -4
	sw $t1, 0($t0)
	addi $t0, $t0, -4
	add $t0, $t0, 128
	sw $t1, 0($t0)
	addi $t0, $t0, -4
	add $t0, $t0, 128
	sw $t1, 0($t0)
	add $t0, $t0, 4
	sw $t1, 0($t0)
	add $t0, $t0, 4
	sw $t1, 0($t0)
	add $t0, $t0, 4
	sw $t1, 0($t0)

	jr $ra
	
drawThree:
	lw $t0, displayAddress
	add $t0, $t0, $t9 #add offset
	sw $t1, 0($t0)
	add $t0, $t0, 4
	sw $t1, 0($t0)
	add $t0, $t0, 4
	sw $t1, 0($t0)
	add $t0, $t0, 128
	sw $t1, 0($t0)
	add $t0, $t0, 128
	sw $t1, 0($t0)
	addi $t0, $t0, -4
	sw $t1, 0($t0)
	addi $t0, $t0, -4
	sw $t1, 0($t0)
	add $t0, $t0, 4
	sw $t1, 0($t0)
	add $t0, $t0, 4
	sw $t1, 0($t0)
	add $t0, $t0, 128
	sw $t1, 0($t0)
	add $t0, $t0, 128
	sw $t1, 0($t0)
	addi $t0, $t0, -4
	sw $t1, 0($t0)
	addi $t0, $t0, -4
	sw $t1, 0($t0)
	
	jr $ra
	
drawFour:
	lw $t0, displayAddress
	add $t0, $t0, $t9 #add offset
	sw $t1, 0($t0)
	add $t0, $t0, 128
	sw $t1, 0($t0)
	add $t0, $t0, 128
	sw $t1, 0($t0)
	add $t0, $t0, 4
	sw $t1, 0($t0)
	add $t0, $t0, 4
	sw $t1, 0($t0)
	addi $t0, $t0, -128
	sw $t1, 0($t0)
	addi $t0, $t0, -128
	sw $t1, 0($t0)
	add $t0, $t0, 128
	sw $t1, 0($t0)
	add $t0, $t0, 128
	sw $t1, 0($t0)
	add $t0, $t0, 128
	sw $t1, 0($t0)
	
	jr $ra
drawFive:
	lw $t0, displayAddress
	add $t0, $t0, $t9 #add offset
	sw $t1, 0($t0)	
	add $t0, $t0, 4
	sw $t1, 0($t0)
	add $t0, $t0, 4
	sw $t1, 0($t0)
	addi $t0, $t0, -4
	addi $t0, $t0, -4
	add $t0, $t0, 128
	sw $t1, 0($t0)
	add $t0, $t0, 128
	sw $t1, 0($t0)
	add $t0, $t0, 4
	sw $t1, 0($t0)
	add $t0, $t0, 4
	sw $t1, 0($t0)
	add $t0, $t0, 128
	sw $t1, 0($t0)
	add $t0, $t0, 128
	sw $t1, 0($t0)
	addi $t0, $t0, -4
	sw $t1, 0($t0)
	addi $t0, $t0, -4
	sw $t1, 0($t0)
	jr $ra
	
drawSix:
	lw $t0, displayAddress
	add $t0, $t0, $t9 #add offset
	sw $t1, 0($t0)
	add $t0, $t0, 4
	sw $t1, 0($t0)
	add $t0, $t0, 4
	sw $t1, 0($t0)
	addi $t0, $t0, -4
	addi $t0, $t0, -4
	add $t0, $t0, 128
	sw $t1, 0($t0)
	add $t0, $t0, 128
	sw $t1, 0($t0)
	add $t0, $t0, 4
	sw $t1, 0($t0)
	add $t0, $t0, 4
	sw $t1, 0($t0)
	add $t0, $t0, 128
	sw $t1, 0($t0)
	add $t0, $t0, 128
	sw $t1, 0($t0)
	addi $t0, $t0, -4
	sw $t1, 0($t0)
	addi $t0, $t0, -4
	sw $t1, 0($t0)
	addi $t0, $t0, -128
	sw $t1, 0($t0)
	addi $t0, $t0, -128
	sw $t1, 0($t0)
	jr $ra
	
drawSeven:
	lw $t0, displayAddress
	add $t0, $t0, $t9 #add offset
	sw $t1, 0($t0)
	sw $t1, 0($t0)
	sw $t1, 0($t0)
	add $t0, $t0, 4
	sw $t1, 0($t0)
	add $t0, $t0, 4
	sw $t1, 0($t0)
	add $t0, $t0, 128
	sw $t1, 0($t0)
	add $t0, $t0, 128
	sw $t1, 0($t0)
	add $t0, $t0, 128
	sw $t1, 0($t0)
	add $t0, $t0, 128
	sw $t1, 0($t0)
	
	jr $ra
	
drawEight:
	lw $t0, displayAddress
	add $t0, $t0, $t9 #add offset
	sw $t1, 0($t0)
	add $t0, $t0, 4
	sw $t1, 0($t0)
	add $t0, $t0, 4
	sw $t1, 0($t0)
	add $t0, $t0, 128
	sw $t1, 0($t0)
	add $t0, $t0, 128
	sw $t1, 0($t0)
	addi $t0, $t0, -4
	sw $t1, 0($t0)
	addi $t0, $t0, -4
	sw $t1, 0($t0)
	addi $t0, $t0, -128
	sw $t1, 0($t0)
	add $t0, $t0, 128
	add $t0, $t0, 128
	sw $t1, 0($t0)
	add $t0, $t0, 128
	sw $t1, 0($t0)
	add $t0, $t0, 4
	sw $t1, 0($t0)
	add $t0, $t0, 4
	sw $t1, 0($t0)
	addi $t0, $t0, -128
	sw $t1, 0($t0)
	addi $t0, $t0, -128
	sw $t1, 0($t0)
	
	jr $ra
	
drawNine:
	lw $t0, displayAddress
	add $t0, $t0, $t9 #add offset
	sw $t1, 0($t0)
	add $t0, $t0, 4
	sw $t1, 0($t0)
	add $t0, $t0, 4
	sw $t1, 0($t0)
	add $t0, $t0, 128
	sw $t1, 0($t0)
	add $t0, $t0, 128
	sw $t1, 0($t0)
	addi $t0, $t0, -4
	sw $t1, 0($t0)
	addi $t0, $t0, -4
	sw $t1, 0($t0)
	addi $t0, $t0, -128
	sw $t1, 0($t0)
	add $t0, $t0, 4
	add $t0, $t0, 4
	add $t0, $t0, 128
	add $t0, $t0, 128
	sw $t1, 0($t0)
	add $t0, $t0, 128
	sw $t1, 0($t0)
	jr $ra
	

displayScore: 

	lw $t2, screenNumber
	li $t3, 10
	bne $t2, 100, keepScore
	sw $zero, screenNumber
	
keepScore:
	
	div $t2, $t3
	mflo $t4
	mfhi $t3
	
	beq $t4, 0, OneDigitNumber
	
	li $t9, 20 
	
	beq $t3, 0, zero
	beq $t3, 1, one
	beq $t3, 2, two
	beq $t3, 3, three
	beq $t3, 4, four
	beq $t3, 5, five
	beq $t3, 6, six
	beq $t3, 7, seven
	beq $t3, 8, eight
	beq $t3, 9, nine

zero:
	
	lw $t1, backgroundColor
	jal drawNine
	lw $t1, scoreColor
	jal drawZero
	
	move $t3, $t4
	j secondNumber
	
one:	
	lw $t1, backgroundColor
	jal drawZero
	lw $t1, scoreColor
	jal drawOne
	
	move $t3, $t4
	j secondNumber
		
	
two:	
	lw $t1, backgroundColor
	jal drawOne
	lw $t1, scoreColor
	jal drawTwo
	
	move $t3, $t4
	j secondNumber				
							
										
	
three:	
	lw $t1, backgroundColor
	jal drawTwo
	lw $t1, scoreColor
	jal drawThree
	
	move $t3, $t4
	j secondNumber				

					
	
four:	
	lw $t1, backgroundColor
	jal drawThree
	lw $t1, scoreColor
	jal drawFour
	
	move $t3, $t4
	j secondNumber				
							
	
five:	
	lw $t1, backgroundColor
	jal drawFour
	lw $t1, scoreColor
	jal drawFive
	
	move $t3, $t4
	j secondNumber				
							
six:	
	lw $t1, backgroundColor
	jal drawFive
	lw $t1, scoreColor
	jal drawSix
	
	move $t3, $t4
	j secondNumber																		
																				
							
seven:	
	lw $t1, backgroundColor
	jal drawSix
	lw $t1, scoreColor
	jal drawSeven
	
	move $t3, $t4
	j secondNumber																		
																		
eight:	
	lw $t1, backgroundColor
	jal drawSeven
	lw $t1, scoreColor
	jal drawEight
	
	move $t3, $t4
	j secondNumber																		
		
																		
nine:	
	lw $t1, backgroundColor
	jal drawEight
	lw $t1, scoreColor
	jal drawNine
	
	move $t3, $t4
	j secondNumber	
	
secondNumber:																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																											
OneDigitNumber:

	li $t9, 0
	beq $t3, 0, Zero
	beq $t3, 1, One
	beq $t3, 2, Two
	beq $t3, 3, Three
	beq $t3, 4, Four
	beq $t3, 5, Five
	beq $t3, 6, Six
	beq $t3, 7, Seven
	beq $t3, 8, Eight
	beq $t3, 9, Nine
	
	
Zero:
	
	lw $t1, scoreColor
	jal drawZero
	j returnDisplay
	
One:	
	lw $t1, backgroundColor
	jal drawZero
	jal drawNine
	lw $t1, scoreColor
	jal drawOne
	j returnDisplay
		
	
Two:	
	lw $t1, backgroundColor
	jal drawOne
	lw $t1, scoreColor
	jal drawTwo
	j returnDisplay				
							
										
	
Three:	
	lw $t1, backgroundColor
	jal drawTwo
	lw $t1, scoreColor
	jal drawThree
	j returnDisplay				

					
	
Four:	
	lw $t1, backgroundColor
	jal drawThree
	lw $t1, scoreColor
	jal drawFour
	j returnDisplay				
							
	
Five:	
	lw $t1, backgroundColor
	jal drawFour
	lw $t1, scoreColor
	jal drawFive
	j returnDisplay				
							
Six:	
	lw $t1, backgroundColor
	jal drawFive
	lw $t1, scoreColor
	jal drawSix
	j returnDisplay																		
																				
							
Seven:	
	lw $t1, backgroundColor
	jal drawSix
	lw $t1, scoreColor
	jal drawSeven
	j returnDisplay																		
																		
Eight:	
	lw $t1, backgroundColor
	jal drawSeven
	lw $t1, scoreColor
	jal drawEight
	j returnDisplay																		
		
																		
Nine:	
	lw $t1, backgroundColor
	jal drawEight
	lw $t1, scoreColor
	jal drawNine
	j returnDisplay	
	

returnDisplay:
        j scoreMaker
	
	
	

Sleep:  li  $v0, 32
        li $a0, 50
        syscall 
	
	jr $ra	
	
SleepForLonger:  li  $v0, 32
        li $a0, 100
        syscall 
	
	jr $ra	

		

Exit:
	li $v0, 10 # terminate the program gracefully
	syscall       
	
	jr $ra	

