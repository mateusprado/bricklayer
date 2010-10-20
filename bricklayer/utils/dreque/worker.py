
import copy
import os
import logging
import signal
import socket
import time
from multiprocessing import Process

from dreque.base import Dreque
from dreque.utils import setprocname

SUPPORTED_DISPATCHERS = ("nofork", "fork") # "pool"

class DrequeWorker(Dreque):
    def __init__(self, queues, server, db=None, dispatcher="fork"):
        self.queues = queues
        self.function_cache = {}
        super(DrequeWorker, self).__init__(server, db)
        self.log = logging.getLogger("dreque.worker")
        self.hostname = socket.gethostname()
        self.pid = os.getpid()
        self.worker_id = "%s:%d" % (self.hostname, self.pid)
        self.dispatcher = dispatcher
        self.child = None
        self._shutdown = None
        if dispatcher not in SUPPORTED_DISPATCHERS:
            raise TypeError("Unsupported dispatcher %s" % dispatcher)

    def work(self, interval=5):
        self.register_worker()
        self.register_signal_handlers()

        setprocname("dreque: Starting")

        self._shutdown = None
        try:
            while not self._shutdown:
                worked = self.work_once()
                if interval == 0:
                    break

                if not worked:
                    setprocname("dreque: Waiting for %s" % ",".join(self.queues))
                    time.sleep(interval)
        finally:
            self.unregister_worker()

    def work_once(self):
        job = self.dequeue(self.queues)
        if not job:
            return False

        try:
            self.working_on(job)
            self.process(job)
        except Exception, exc:
            import traceback
            self.log.warning("Job failed (%s): %s\n%s" % (job, str(exc), traceback.format_exc()))
            # Requeue
            queue = job.pop("queue")
            if 'fail' not in job:
                job['fail'] = [str(exc)]
            else:
                job['fail'].append(str(exc))
            job['retries_left'] = job.get('retries_left', 1) - 1
            if job['retries_left'] > 0:
                self.push(queue, job, 2**len(job['fail']))
                self.stats.incr("retries")
                self.stats.incr("retries:" + self.worker_id)
            else:
                self.failed()
        else:
            self.done_working()

        return True

    def process(self, job):
        if self.dispatcher == "fork":
            child = Process(target=self.dispatch_child, args=(job,))
            child.start()
            self.child = child
            setprocname("dreque: Forked %d at %d" % (child.pid, time.time()))
            while True:
                try:
                    child.join()
                except OSError, exc:
                    if 'Interrupted system call' not in exc:
                        raise
                    continue
                break
            self.child = None

            if child.exitcode != 0:
                raise Exception("Job failed with exitcode %d" % child.exitcode)
        else: # nofork
            self.dispatch(copy.deepcopy(job))

    def dispatch_child(self, job):
        self.reset_signal_handlers()
        self.dispatch(job)

    def dispatch(self, job):
        setprocname("dreque: Processing %s since %d" % (job['queue'], time.time()))
        func = self.lookup_function(job['func'])
        kwargs = dict((str(k), v) for k, v in job['kwargs'].items())
        func(*job['args'], **kwargs)

    #

    def register_signal_handlers(self):
        signal.signal(signal.SIGTERM, lambda signum,frame:self.shutdown())
        signal.signal(signal.SIGINT, lambda signum,frame:self.shutdown())
        signal.signal(signal.SIGQUIT, lambda signum,frame:self.graceful_shutdown())
        signal.signal(signal.SIGUSR1, lambda signum,frame:self.kill_child())

    def reset_signal_handlers(self):
        signal.signal(signal.SIGTERM, signal.SIG_DFL)
        signal.signal(signal.SIGINT, signal.SIG_DFL)
        signal.signal(signal.SIGQUIT, signal.SIG_DFL)
        signal.signal(signal.SIGUSR1, signal.SIG_DFL)

    def shutdown(self, signum=None, frame=None):
        """Shutdown immediately without waiting for job to complete"""
        self.log.info("Worker %s shutting down" % self.worker_id)
        self._shutdown = "forced"
        self.kill_child()

    def graceful_shutdown(self, signum=None, frame=None):
        """Shutdown gracefully waiting for job to finish"""
        self.log.info("Worker %s shutting down gracefully" % self.worker_id)
        self._shutdown = "graceful"

    def kill_child(self):
        if self.child:
            self.log.info("Killing child %s" % self.child)
            if self.child.is_alive():
                self.child.terminate()
            self.child = None

    #

    def register_worker(self):
        self.redis.sadd(self._redis_key("workers"), self.worker_id)

    def unregister_worker(self):
        self.redis.srem(self._redis_key("workers"), self.worker_id)
        self.redis.delete(self._redis_key("worker:%s:started" % self.worker_id))
        self.stats.clear("processed:"+self.worker_id)
        self.stats.clear("failed:"+self.worker_id)

    def working_on(self, job):
        self.redis.set(self._redis_key("worker:"+self.worker_id),
            dict(
                queue = job['queue'],
                func = job['func'],
                args = job['args'],
                kwargs = job['kwargs'],
                run_at = time.time(),
            ))

    def done_working(self):
        self.processed()
        self.redis.delete(self._redis_key("worker:"+self.worker_id))

    def processed(self):
        self.stats.incr("processed")
        self.stats.incr("processed:" + self.worker_id)

    def failed(self):
        self.stats.incr("failed")
        self.stats.incr("failed:" + self.worker_id)

    def started(self):
        self.redis.set("worker:%s:started" % self.worker_id, time.time())

    def lookup_function(self, name):
        try:
            return self.function_cache[name]
        except KeyError:
            mod_name, func_name = name.rsplit('.', 1)
            mod = __import__(str(mod_name), {}, {}, [str(func_name)])
            func = getattr(mod, func_name)
            self.function_cache[name] = func
        return func

    #

    def workers(self):
        return self.redis.smembers(self._redis_key("workers"))

    def working(self):
        workers = self.list_workers()
        if not workers:
            return []

        keys = [self._redis_key("worker:"+x) for x in workers]
        return dict((x, y) for x, y in zip(self.redis.mget(workers, keys)))

    def worker_exists(self, worker_id):
        return self.redis.sismember(self._redis_key("workers"), worker_id)
