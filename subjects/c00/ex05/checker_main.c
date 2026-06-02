/* checker_main.c – ft_print_comb (C00 ex05) */
#include <unistd.h>
void	ft_print_comb(void);
int	main(void)
{
	ft_print_comb();
	write(1, "\n", 1);
	return (0);
}
/* EXPECTED_PARTIAL_START
012, 013, 014
*/
/* EXPECTED_PARTIAL_END
789
*/
/* CHECK_MODE: partial */
