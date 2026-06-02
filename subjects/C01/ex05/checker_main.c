/* checker_main.c – ft_putstr (C01 ex05) */
#include <unistd.h>
void	ft_putstr(char *str);
int	main(void)
{
	ft_putstr("Hello, 42!");
	write(1, "\n", 1);
	ft_putstr("Piscine");
	write(1, "\n", 1);
	return (0);
}
/* EXPECTED_OUTPUT
Hello, 42!
Piscine
*/
