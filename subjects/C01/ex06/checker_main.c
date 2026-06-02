/* checker_main.c – ft_strlen (C01 ex06) */
#include <unistd.h>
int	ft_strlen(char *str);
static void	putnbr(int n)
{
	char c;
	if (n >= 10) putnbr(n / 10);
	c = '0' + (n % 10);
	write(1, &c, 1);
}
int	main(void)
{
	putnbr(ft_strlen("Hello")); write(1, "\n", 1);
	putnbr(ft_strlen(""));      write(1, "\n", 1);
	putnbr(ft_strlen("42"));    write(1, "\n", 1);
	return (0);
}
/* EXPECTED_OUTPUT
5
0
2
*/
