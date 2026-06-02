/* checker_main.c – ft_print_combn (C00 ex08) */
#include <unistd.h>
void	ft_print_combn(int n);
int	main(void)
{
	ft_print_combn(2);
	write(1, "\n", 1);
	return (0);
}
/* EXPECTED_PARTIAL_START
01, 02, 03
*/
/* EXPECTED_PARTIAL_END
89
*/
/* CHECK_MODE: partial */
