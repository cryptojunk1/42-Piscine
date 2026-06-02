/* checker_main.c – ft_print_numbers (C00 ex03) */
#include <unistd.h>
void	ft_print_numbers(void);
int	main(void)
{
	ft_print_numbers();
	write(1, "\n", 1);
	return (0);
}
/* EXPECTED_OUTPUT
0123456789
*/
