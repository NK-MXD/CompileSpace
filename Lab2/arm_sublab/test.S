	movs	r3, #0
	str	r3, [1000]  ;int a = 0;
	movs	r3, #1
	str	r3, [2000]  ;int b = 1;
	movs	r3, #0
	str	r3, [3000]  ;int i = 0;
	b	BACK
LOOP:
	ldr	r2, [2000] 
	ldr	r3, [3000]
	add	r3, r3, r2
	str	r3, [1000]
	ldr	r3, [3000]
	adds	r3, r3, #1
	str	r3, [3000]  ;a = b + i;
BACK:
	ldr	r3, [3000]
	cmp	r3, #9      ;i < 10;
	ble	LOOP
OUT:

