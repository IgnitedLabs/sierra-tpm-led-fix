using System;
using System.IO;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;
using System.Threading;

public class SierraLEDDriver
{
    [DllImport("hid.dll")] static extern void HidD_GetHidGuid(out Guid g);
    [DllImport("setupapi.dll", CharSet=CharSet.Auto)] static extern IntPtr SetupDiGetClassDevs(ref Guid g, IntPtr e, IntPtr h, uint f);
    [DllImport("setupapi.dll", CharSet=CharSet.Auto)] static extern bool SetupDiEnumDeviceInterfaces(IntPtr h, IntPtr d, ref Guid g, uint i, ref SP_DID did);
    [DllImport("setupapi.dll", CharSet=CharSet.Auto)] static extern bool SetupDiGetDeviceInterfaceDetail(IntPtr h, ref SP_DID did, IntPtr det, uint s, out uint n, IntPtr di);
    [DllImport("setupapi.dll", CharSet=CharSet.Auto)] static extern bool SetupDiGetDeviceInterfaceDetail(IntPtr h, ref SP_DID did, ref SP_DET det, uint s, out uint n, IntPtr di);
    [DllImport("kernel32.dll", CharSet=CharSet.Auto, SetLastError=true)] static extern SafeFileHandle CreateFile(string f, uint a, uint sh, IntPtr sa, uint c, uint fl, IntPtr t);
    [DllImport("hid.dll", SetLastError=true)] static extern bool HidD_SetOutputReport(SafeFileHandle h, byte[] b, uint l);
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode)] static extern IntPtr LoadLibraryW(string path);
    [DllImport("kernel32.dll", CharSet=CharSet.Ansi)] static extern IntPtr GetProcAddress(IntPtr hModule, string name);

    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    delegate int DSimConnect_Open(out IntPtr phSC, [MarshalAs(UnmanagedType.LPStr)] string szName, IntPtr hWnd, uint UserEventWin32, IntPtr hEvent, uint ConfigIndex);
    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    delegate int DSimConnect_Close(IntPtr hSC);
    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    delegate int DSimConnect_AddToDataDefinition(IntPtr hSC, uint DefineID, [MarshalAs(UnmanagedType.LPStr)] string DatumName, [MarshalAs(UnmanagedType.LPStr)] string UnitsName, uint DatumType, float fEpsilon, uint DatumID);
    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    delegate int DSimConnect_RequestDataOnSimObject(IntPtr hSC, uint RequestID, uint DefineID, uint ObjectID, uint Period, uint Flags, uint origin, uint interval, uint limit);
    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    delegate int DSimConnect_GetNextDispatch(IntPtr hSC, out IntPtr ppData, out uint pcbData);

    [StructLayout(LayoutKind.Sequential)] struct SP_DID { public int cbSize; public Guid g; public int f; public IntPtr r; }
    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Auto)] struct SP_DET { public int cbSize; [MarshalAs(UnmanagedType.ByValTStr, SizeConst=256)] public string Path; }

    static SafeFileHandle hidHandle;
    static byte lastLedByte = 0xFF;

    static SafeFileHandle OpenSierra()
    {
        Guid hg; HidD_GetHidGuid(out hg);
        IntPtr di = SetupDiGetClassDevs(ref hg, IntPtr.Zero, IntPtr.Zero, 0x12);
        uint ix = 0; SP_DID did = new SP_DID(); did.cbSize = Marshal.SizeOf(did);
        while (SetupDiEnumDeviceInterfaces(di, IntPtr.Zero, ref hg, ix++, ref did))
        {
            uint n; SetupDiGetDeviceInterfaceDetail(di, ref did, IntPtr.Zero, 0, out n, IntPtr.Zero);
            SP_DET det = new SP_DET(); det.cbSize = IntPtr.Size == 8 ? 8 : 5;
            SetupDiGetDeviceInterfaceDetail(di, ref did, ref det, n, out n, IntPtr.Zero);
            if (det.Path != null &&
                det.Path.ToLower().Contains("vid_294b") &&
                det.Path.ToLower().Contains("pid_190d") &&
                det.Path.ToLower().Contains("col02"))
                return CreateFile(det.Path, 0xC0000000, 3, IntPtr.Zero, 3, 0, IntPtr.Zero);
        }
        return null;
    }

    static string FindSimConnect()
    {
        // Search common install locations for SimConnect_internal.dll
        string[] searchRoots = {
            @"C:\XboxGames",
            @"D:\XboxGames",
            @"E:\XboxGames",
            @"C:\Program Files\WindowsApps",
            @"D:\Program Files\WindowsApps",
            @"C:\Games",
            @"D:\Games"
        };

        foreach (string root in searchRoots)
        {
            if (!Directory.Exists(root)) continue;
            try
            {
                string[] files = Directory.GetFiles(root, "SimConnect_internal.dll", SearchOption.AllDirectories);
                foreach (string f in files)
                {
                    if (f.Contains("Flight Simulator")) return f;
                }
            }
            catch {}
        }
        return null;
    }

    static void SetLEDs(byte ledByte)
    {
        if (ledByte != lastLedByte)
        {
            byte[] report = new byte[63];
            report[0] = 101;
            report[2] = ledByte;
            HidD_SetOutputReport(hidHandle, report, 63);
            lastLedByte = ledByte;
        }
    }

    static byte ComputeLEDs(double amps, double gearL, double gearC, double gearR)
    {
        if (amps < 1.0) return 0x00;
        byte led = 0;
        if (gearL >= 1.0)      led |= 0x01; else if (gearL > 0.0) led |= 0x02;
        if (gearC >= 1.0)      led |= 0x04; else if (gearC > 0.0) led |= 0x08;
        if (gearR >= 1.0)      led |= 0x10; else if (gearR > 0.0) led |= 0x20;
        return led;
    }

    static void LEDsOff()
    {
        try
        {
            if (hidHandle != null && !hidHandle.IsInvalid && !hidHandle.IsClosed)
            {
                byte[] report = new byte[63];
                report[0] = 101;
                report[2] = 0x00;
                HidD_SetOutputReport(hidHandle, report, 63);
            }
        }
        catch {}
    }

    public static int Main(string[] args)
    {
        AppDomain.CurrentDomain.ProcessExit += (s, e) => LEDsOff();

        // Open Sierra HID - retry for up to 30 seconds
        for (int i = 0; i < 30; i++)
        {
            hidHandle = OpenSierra();
            if (hidHandle != null && !hidHandle.IsInvalid) break;
            hidHandle = null;
            Thread.Sleep(1000);
        }
        if (hidHandle == null) return 1;

        // Find and load SimConnect
        string scPath = FindSimConnect();
        if (scPath == null) { hidHandle.Close(); return 1; }

        IntPtr scDll = LoadLibraryW(scPath);
        if (scDll == IntPtr.Zero) { hidHandle.Close(); return 1; }

        var scOpen = (DSimConnect_Open)Marshal.GetDelegateForFunctionPointer(GetProcAddress(scDll, "SimConnect_Open"), typeof(DSimConnect_Open));
        var scClose = (DSimConnect_Close)Marshal.GetDelegateForFunctionPointer(GetProcAddress(scDll, "SimConnect_Close"), typeof(DSimConnect_Close));
        var scAddDef = (DSimConnect_AddToDataDefinition)Marshal.GetDelegateForFunctionPointer(GetProcAddress(scDll, "SimConnect_AddToDataDefinition"), typeof(DSimConnect_AddToDataDefinition));
        var scReqData = (DSimConnect_RequestDataOnSimObject)Marshal.GetDelegateForFunctionPointer(GetProcAddress(scDll, "SimConnect_RequestDataOnSimObject"), typeof(DSimConnect_RequestDataOnSimObject));
        var scDispatch = (DSimConnect_GetNextDispatch)Marshal.GetDelegateForFunctionPointer(GetProcAddress(scDll, "SimConnect_GetNextDispatch"), typeof(DSimConnect_GetNextDispatch));

        // Connect to SimConnect - retry for up to 2 minutes
        IntPtr hSC = IntPtr.Zero;
        for (int attempt = 0; attempt < 60; attempt++)
        {
            if (scOpen(out hSC, "Sierra LED Driver", IntPtr.Zero, 0, IntPtr.Zero, 0) == 0) break;
            hSC = IntPtr.Zero;
            Thread.Sleep(2000);
        }
        if (hSC == IntPtr.Zero) { hidHandle.Close(); return 1; }

        // Subscribe to gear + electrical data
        scAddDef(hSC, 0, "ELECTRICAL TOTAL LOAD AMPS", "Amperes", 4, 0, 0xFFFFFFFF);
        scAddDef(hSC, 0, "GEAR LEFT POSITION", "percent over 100", 4, 0, 0xFFFFFFFF);
        scAddDef(hSC, 0, "GEAR CENTER POSITION", "percent over 100", 4, 0, 0xFFFFFFFF);
        scAddDef(hSC, 0, "GEAR RIGHT POSITION", "percent over 100", 4, 0, 0xFFFFFFFF);
        scReqData(hSC, 0, 0, 0, 3, 0, 0, 0, 0);

        // Main loop with MSFS exit detection
        bool running = true;
        int noDataCount = 0;

        while (running)
        {
            IntPtr pData; uint cbData;
            bool gotData = false;

            while (scDispatch(hSC, out pData, out cbData) == 0)
            {
                gotData = true;
                noDataCount = 0;
                uint dwID = (uint)Marshal.ReadInt32(pData, 8);

                if (dwID == 8 && cbData >= 72)
                {
                    double amps  = BitConverter.Int64BitsToDouble(Marshal.ReadInt64(pData, 40));
                    double gearL = BitConverter.Int64BitsToDouble(Marshal.ReadInt64(pData, 48));
                    double gearC = BitConverter.Int64BitsToDouble(Marshal.ReadInt64(pData, 56));
                    double gearR = BitConverter.Int64BitsToDouble(Marshal.ReadInt64(pData, 64));
                    SetLEDs(ComputeLEDs(amps, gearL, gearC, gearR));
                }
                else if (dwID == 3)
                {
                    running = false;
                    break;
                }
            }

            if (!gotData) noDataCount++;
            if (noDataCount > 300) running = false;

            Thread.Sleep(16);
        }

        LEDsOff();
        try { scClose(hSC); } catch {}
        hidHandle.Close();
        return 0;
    }
}
