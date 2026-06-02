/* checker_main.c – ft_ultimate_ft (C01 ex01) */
#include <unistd.h>
void	ft_ultimate_ft(int *********nbr);
static void	putnbr(int n)
{
	char c;
	if (n >= 10) putnbr(n / 10);
	c = '0' + (n % 10);
	write(1, &c, 1);
}
int	main(void)
{
	int	n = 0;
	int	*p1=&n, **p2=&p1, ***p3=&p2, ****p4=&p3;
	int	*****p5=&p4, ******p6=&p5, *******p7=&p6;
	int	********p8=&p7, *********p9=&p8;
	ft_ultimate_ft(p9);
	putnbr(n);
	write(1, "\n", 1);
	return (0);
}
/* EXPECTED_OUTPUT
42
*/
