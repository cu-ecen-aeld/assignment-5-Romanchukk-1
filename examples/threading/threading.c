#include "threading.h"
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

// Optional: use these functions to add debug or error prints to your application
#define DEBUG_LOG(msg,...)
//#define DEBUG_LOG(msg,...) printf("threading: " msg "\n" , ##__VA_ARGS__)
#define ERROR_LOG(msg,...) printf("threading ERROR: " msg "\n" , ##__VA_ARGS__)

void* threadfunc(void* thread_param)
{
    // TODO: wait, obtain mutex, wait, release mutex as described by thread_data structure
    DEBUG_LOG("Thread is running");
 
    thread_data_t* thread_func_args = (thread_data_t *) thread_param;
    
    usleep(thread_func_args->wait_delay_ms * 1000);
    int res = pthread_mutex_lock(thread_func_args->mtx);
    if (res != 0) {
        goto err;
    }

    usleep(thread_func_args->wait_delay_ms * 1000);
    res = pthread_mutex_unlock(thread_func_args->mtx);

    if (res == 0) {
        thread_func_args->thread_complete_success = true;
    }
    
err:
    return thread_param;
}


bool start_thread_obtaining_mutex(pthread_t *thread, pthread_mutex_t *mutex,int wait_to_obtain_ms, int wait_to_release_ms)
{
    /**
     * TODO: allocate memory for thread_data, setup mutex and wait arguments, pass thread_data to created thread
     * using threadfunc() as entry point.
     *
     * return true if successful.
     *
     * See implementation details in threading.h file comment block
     */
    DEBUG_LOG("Create thread");

    thread_data_t *tdata = malloc(sizeof(thread_data_t) * 1);
    if (tdata == NULL) {
        ERROR_LOG("Failed to allocate data for thread argument");
        return false;
    }

    tdata->mtx = mutex;
    tdata->release_delay_ms = wait_to_release_ms;
    tdata->wait_delay_ms = wait_to_obtain_ms;
    tdata->thread_complete_success = false;

    // int res = pthread_mutex_init(tdata->mtx, NULL);
    // if (res != 0) {
    //     ERROR_LOG("Failed to init mutex");
    //     free(tdata);
    //     return false;
    // }

    // pthread_attr_t attr;
    // pthread_attr_init(&attr);
    // pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
    
    int rc = pthread_create(
        thread,
        NULL,
        threadfunc,
        tdata
    );
    //pthread_attr_destroy(&attr);
    
    if (rc != 0) {
        ERROR_LOG("Failed to run thread: %d", rc);
        free(tdata);
        return false;
    }

    return true;
}

