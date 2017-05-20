#include <windows.h>
#include <stdio.h>
#include <string.h>
#include <psapi.h>

int main(int argc, char** argv)
{
	if (argc < 2)
	{
		printf("No PID specified!\n");
		return 1;
	}
	DWORD pid;
	sscanf(argv[1], "%ld", &pid);
	HANDLE hProcess;
    PROCESS_MEMORY_COUNTERS pmc;

    // Print information about the memory usage of the process.

    hProcess = OpenProcess(  PROCESS_QUERY_INFORMATION |
                                    PROCESS_VM_READ,
                                    FALSE, pid);
	if ( GetProcessMemoryInfo( hProcess, &pmc, sizeof(pmc)) )
    {
		printf( "%ld\n", (pmc.PeakWorkingSetSize) / (1024*1024) );
	}
	CloseHandle(hProcess);
	return 0;
}
