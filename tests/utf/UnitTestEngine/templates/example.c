/* This is the example _original_ file */

static int function1(int input)
{
	switch(input)
	{
		case 1:
			return 2;
		case 2:
			return 4;
		default:
			return 0;
	}
}

int function2(int input)
{
	switch(function1(input))
	{
		
		case 2:
			return 1;
		case 4:
			return 1;
		default:
			return 0;
		
	}
}
