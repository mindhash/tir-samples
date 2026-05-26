import os
import torch
import torch.distributed as dist

TRIALS = 10

# 256MB
NUM_ELEMENTS = 10000 * 1024 * 1024 // 4

def timed_broadcast(tensor):

    torch.cuda.synchronize()

    start = torch.cuda.Event(enable_timing=True)
    end = torch.cuda.Event(enable_timing=True)

    start.record()

    dist.broadcast(tensor, src=0)

    end.record()

    torch.cuda.synchronize()

    duration_s = start.elapsed_time(end) / 1000.0

    bytes_sent = tensor.numel() * tensor.element_size()

    gbps = (bytes_sent / duration_s) / 1e9

    return gbps, duration_s


def main():

    rank = int(os.environ["RANK"])
    local_rank = int(os.environ.get("LOCAL_RANK", 0))

    torch.cuda.set_device(local_rank)

    dist.init_process_group("nccl")

    print(
        f"rank={rank} "
        f"local_rank={local_rank} "
        f"cuda={torch.cuda.current_device()} "
        f"host={os.uname().nodename}"
    )

    tensor = torch.ones(
        NUM_ELEMENTS,
        dtype=torch.float32,
        device="cuda"
    )

    # warmup
    for _ in range(3):
        timed_broadcast(tensor)

    results = []

    for i in range(TRIALS):

        gbps, duration = timed_broadcast(tensor)

        results.append(gbps)

        if rank == 0:
            print(
                f"trial={i} "
                f"time={duration:.6f}s "
                f"bw={gbps:.2f} GB/s "
                f"({gbps*8:.1f} Gbps)"
            )

    if rank == 0:

        avg = sum(results) / len(results)

        print("\n====================")
        print(f"Average: {avg:.2f} GB/s ({avg*8:.1f} Gbps)")
        print("====================")


if __name__ == "__main__":
    main()
