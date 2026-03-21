#include <stdlib.h>
#include <stdio.h>

#include <unistd.h>
#include <sys/types.h>

int main(void )
{
    pid_t pid;
    
    pid = fork();
    
    if (pid > 0)
        printf ("I am the parent of pid=%d!\n", pid);
    else if (!pid)
        printf ("I am the baby!\n");
    else if (pid == -1)
        perror ("fork");

    return EXIT_SUCCESS;
}