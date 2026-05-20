# **winsat-gui**

**winsat-gui** is a modern, high-performance graphical interface for the Windows System Assessment Tool (winsat.exe).

Designed for system administrators, PC builders, and power users, this tool eliminates the need for complex command-line syntax while maintaining 100% feature parity with the native WinSAT engine. It wraps the powerful hardware benchmarking capabilities of Windows into an intuitive, responsive, and fully self-contained desktop application.

## **🚀 Power Features**

* **Single-File Portability:** The entire application—including the complex WPF layout (XAML) and asynchronous execution logic—is contained within a single .ps1 file. No installations, no compiled binaries, no external dependencies.  
* **Asynchronous, Non-Blocking Engine:** Built using System.Diagnostics.Process with background threading, the application executes heavy hardware benchmarks without ever freezing the UI.  
* **Real-Time Output Streaming:** Standard Output (STDOUT) and Standard Error (STDERR) are intercepted at the stream level and piped directly into the application's built-in console in real-time.  
* **Dynamic Command Generation & Validation:** The UI is context-aware. Switches and options (like D3D modes or Restart behaviors) dynamically enable or disable based on the selected core command, preventing syntax errors before they happen.  
* **Integrated Dynamic Help:** A built-in, context-sensitive help engine automatically updates to explain the currently selected command, removing the need for external documentation.  
* **Live Command Preview:** See the exact CLI syntax being generated in real-time, with a quick-copy button for integration into other scripts.

## **🛠️ Technical Specifications**

* **Architecture:** Native Windows Desktop Application (Single-File PowerShell Script).  
* **Frontend:** C\# WPF (Windows Presentation Foundation) XAML embedded natively via System.Windows.Markup.XamlReader.  
* **Backend Engine:** Windows System Assessment Tool (winsat.exe).  
* **Framework Requirements:** PowerShell 5.1+ and .NET Framework (PresentationFramework, PresentationCore).  
* **Encoding:** Fully ANSI/UTF-8-BOM compatible design, immune to multi-byte character corruption during execution.

## **🎯 Power Uses & Scenarios**

1. **System Builders & Overclockers:** Easily run isolated subsystem stress tests (e.g., winsat cpu, winsat mem, winsat d3d) with verbose output to verify stability and hardware performance without remembering complex syntax.  
2. **Enterprise Sysadmins (Prepopulation):** Utilize the prepop commands to generate baseline XML hardware data for enterprise imaging and deployment via SCCM/MDT. The GUI makes it easy to target specific datastore directories.  
3. **Troubleshooting & Diagnostics:** Use the utility tools (viewlog, viewevents) directly from the GUI to instantly diagnose hardware assessment failures or DWM (Desktop Window Manager) crashes.  
4. **Benchmarking History Management:** Use the \-restart clean or forgethistory commands to wipe old hardware scores after upgrading PC components (like swapping a GPU).

## **🧰 Command Capabilities**

**winsat-gui** maps to all major WinSAT functions:

* **Assessments:** formal, dwm, cpu, mem, d3d, disk, media, mfmedia, features  
* **Formal Scores:** dwmformal, cpuformal, memformal, graphicsformal, diskformal  
* **Prepopulation:** prepop (Global, Graphics, CPU, Memory, Disk, DWM)  
* **Sub-Assessments:** graphicsformal3d, graphicsformalmedia  
* **Utilities:** viewlog, viewevents, query, forgethistory

**Supported Switches:**

* \-v (Verbose logging)  
* \-eef (Extended features enumeration)  
* \-restart \[default|clean|never\]  
* \-dx9 / \-dx10 (Direct3D forcing)  
* XML output routing, Log file generation, and custom Datastore targeting.

## **⚙️ How to Use**

1. Download the winsat-gui.ps1 script.  
2. Right-click the script and select **Run with PowerShell** (or execute it via a PowerShell terminal).  
3. **Note:** Because WinSAT performs low-level hardware benchmarking, the script **must be run as Administrator**. The GUI will gracefully alert you if it is launched without elevated privileges.

*Created by [Joshua Dwight](https://github.com/joshdwight101)*