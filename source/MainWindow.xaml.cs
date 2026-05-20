using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Security.Principal;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Documents;
using System.Windows.Markup;
using System.Windows.Media;
using System.Windows.Threading;

namespace winsat_gui
{
    public partial class MainWindow : Window
    {
        // Initialize the dictionary directly to satisfy the nullable strictness compiler checks
        private Dictionary<string, string[]> _categories = new Dictionary<string, string[]>
        {
            { "Assessments", new[] { "formal", "dwm", "cpu", "mem", "d3d", "disk", "media", "mfmedia", "features" } },
            { "Formal Scores", new[] { "dwmformal", "cpuformal", "memformal", "graphicsformal", "diskformal" } },
            { "Prepopulation", new[] { "prepop", "prepop -graphics", "prepop -cpu", "prepop -mem", "prepop -disk", "prepop -dwm" } },
            { "Sub-Assessments", new[] { "graphicsformal3d", "graphicsformalmedia" } },
            { "Utilities", new[] { "viewlog", "viewevents", "query", "forgethistory" } }
        };

        private Process? _activeProcess;
        private Stopwatch _stopwatch;
        private DispatcherTimer _timer;

        public MainWindow()
        {
            InitializeComponent();

            _stopwatch = new Stopwatch();
            _timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(500) };
            _timer.Tick += Timer_Tick;

            InitializeEvents();
            LoadCategory("Assessments");
        }

        private void InitializeEvents()
        {
            // Navigation
            navAssessments.Click += (s, e) => { SetNavStyle(navAssessments); LoadCategory("Assessments"); };
            navFormal.Click += (s, e) => { SetNavStyle(navFormal); LoadCategory("Formal Scores"); };
            navPrepop.Click += (s, e) => { SetNavStyle(navPrepop); LoadCategory("Prepopulation"); };
            navSub.Click += (s, e) => { SetNavStyle(navSub); LoadCategory("Sub-Assessments"); };
            navUtils.Click += (s, e) => { SetNavStyle(navUtils); LoadCategory("Utilities"); };
            navAbout.Click += NavAbout_Click;

            lnkGithub.RequestNavigate += (s, e) => {
                Process.Start(new ProcessStartInfo("https://github.com/joshdwight101") { UseShellExecute = true });
                e.Handled = true;
            };
            
            lnkDatastore.RequestNavigate += (s, e) => {
                string path = @"C:\Windows\Performance\WinSAT\Datastore";
                if (Directory.Exists(path)) {
                    Process.Start(new ProcessStartInfo(path) { UseShellExecute = true });
                }
                e.Handled = true;
            };

            // Options Changes
            cmbCommand.SelectionChanged += (s, e) => UpdateCommandState();
            chkVerbose.Click += (s, e) => UpdatePreview();
            chkEef.Click += (s, e) => UpdatePreview();
            cmbRestart.SelectionChanged += (s, e) => UpdatePreview();
            cmbD3d.SelectionChanged += (s, e) => UpdatePreview();
            txtXml.TextChanged += (s, e) => UpdatePreview();
            txtLog.TextChanged += (s, e) => UpdatePreview();
            txtDatastore.TextChanged += (s, e) => UpdatePreview();

            // Browse Buttons
            btnBrowseXml.Click += (s, e) => {
                var dlg = new Microsoft.Win32.SaveFileDialog { Filter = "XML Files (*.xml)|*.xml|All Files (*.*)|*.*" };
                if (dlg.ShowDialog() == true) txtXml.Text = dlg.FileName;
            };

            btnBrowseLog.Click += (s, e) => {
                var dlg = new Microsoft.Win32.SaveFileDialog { Filter = "Log Files (*.log)|*.log|All Files (*.*)|*.*" };
                if (dlg.ShowDialog() == true) txtLog.Text = dlg.FileName;
            };

            btnBrowseDatastore.Click += (s, e) => {
                var dlg = new System.Windows.Forms.FolderBrowserDialog { Description = "Select Datastore Directory" };
                if (dlg.ShowDialog() == System.Windows.Forms.DialogResult.OK) {
                    txtDatastore.Text = dlg.SelectedPath;
                }
            };

            // Execute Buttons
            btnCopy.Click += (s, e) => Clipboard.SetText(txtPreview.Text);
            btnRun.Click += BtnRun_Click;
            btnStop.Click += BtnStop_Click;
        }

        private void SetNavStyle(Button activeButton)
        {
            navAssessments.Style = (Style)FindResource("NavButtonStyle");
            navFormal.Style = (Style)FindResource("NavButtonStyle");
            navPrepop.Style = (Style)FindResource("NavButtonStyle");
            navSub.Style = (Style)FindResource("NavButtonStyle");
            navUtils.Style = (Style)FindResource("NavButtonStyle");
            
            activeButton.Style = (Style)FindResource("ActiveNavButtonStyle");
        }

        private void LoadCategory(string categoryName)
        {
            cmbCommand.Items.Clear();
            foreach (var item in _categories[categoryName])
            {
                cmbCommand.Items.Add(item);
            }
            if (cmbCommand.Items.Count > 0) cmbCommand.SelectedIndex = 0;
            UpdateCommandState();
        }

        private void UpdateCommandState()
        {
            string? selected = cmbCommand.SelectedItem as string;
            if (string.IsNullOrEmpty(selected)) return;

            chkEef.IsEnabled = (selected == "features");
            if (!chkEef.IsEnabled) chkEef.IsChecked = false;

            cmbRestart.IsEnabled = (selected == "formal");
            if (!cmbRestart.IsEnabled) cmbRestart.SelectedIndex = 0;

            cmbD3d.IsEnabled = (selected == "d3d");
            if (!cmbD3d.IsEnabled) cmbD3d.SelectedIndex = 0;

            bool isPrepop = selected.StartsWith("prepop");
            txtDatastore.IsEnabled = isPrepop;
            btnBrowseDatastore.IsEnabled = isPrepop;

            UpdatePreview();
            UpdateHelpContent();
        }

        private void UpdateHelpContent()
        {
            string? cmd = cmbCommand.SelectedItem as string;
            if (string.IsNullOrEmpty(cmd)) return;

            string title = $"Command: {cmd}";
            string desc = "";
            string nl = Environment.NewLine;

            if (cmd == "formal") desc = $"Runs the full set of assessments to generate overall system scores.{nl}{nl}Restart Option:{nl}- default: WinSAT determines whether to rerun.{nl}- clean: Reruns all assessments and clears history.{nl}- never: Attempts incremental run if possible.";
            else if (cmd == "dwm") desc = "Runs the Desktop Windows Manager assessment and restarts the DWM process.";
            else if (cmd == "cpu") desc = "Runs the CPU assessment.";
            else if (cmd == "mem") desc = "Runs the system memory assessment.";
            else if (cmd == "d3d") desc = $"Runs the Direct3D assessment.{nl}{nl}D3D Mode:{nl}- -dx9: Run DirectX 9 sub-assessments.{nl}- -dx10: Run DirectX 10 sub-assessments.";
            else if (cmd == "disk") desc = "Runs the storage assessment.";
            else if (cmd == "media") desc = "Runs the media assessment.";
            else if (cmd == "mfmedia") desc = "Runs the Media Foundation based assessment.";
            else if (cmd == "features") desc = $"Enumerates the system's features.{nl}{nl}-eef (Extended Features):{nl}Used with the features command to enumerate extended features like optical disks and memory modules.";
            else if (cmd.StartsWith("prepop")) desc = $"Generates pre-population WinSAT XML files. You can target specific subsystems (graphics, cpu, mem, disk, dwm).{nl}{nl}Datastore Option:{nl}Specifies the target directory where prepopulation XML files will be stored. Defaults to the standard WinSAT datastore.";
            else if (cmd.Contains("formal")) desc = "Runs a specific formal sub-assessment to generate a specific WinSAT score (e.g., Gaming Graphics, CPU, Memory). Results are directly saved to the Windows Datastore.";
            else if (cmd == "viewlog") desc = "Dumps the results of a previously specified log file to the console.";
            else if (cmd == "viewevents") desc = "Opens the Windows Event Viewer to display relevant WinSAT events.";
            else if (cmd == "query") desc = "Queries the current WinSAT datastore for existing system scores.";
            else if (cmd == "forgethistory") desc = "Clears the existing WinSAT history, effectively rating the machine as if for the first time.";
            else desc = "Select a command to view detailed help and usage information.";

            string commonOptions = $"{nl}{nl}Common Output Options:{nl}- XML Output: Saves the assessment results to the specified XML file.{nl}- Log File: Generates a log file for troubleshooting and analysis.{nl}- Verbose (-v): Enables detailed diagnostic output during execution.";

            txtHelpTitle.Text = title;
            txtHelpText.Text = desc + commonOptions;
        }

        private void UpdatePreview()
        {
            string? selected = cmbCommand.SelectedItem as string;
            if (string.IsNullOrEmpty(selected)) return;

            string cmd = $"winsat {selected}";

            if (chkVerbose.IsChecked == true) cmd += " -v";
            if (chkEef.IsChecked == true && chkEef.IsEnabled) cmd += " -eef";

            if (cmbRestart.IsEnabled && cmbRestart.SelectedIndex > 0)
                cmd += $" -restart {((ComboBoxItem)cmbRestart.SelectedItem).Content}";

            if (cmbD3d.IsEnabled && cmbD3d.SelectedIndex > 0)
                cmd += $" {((ComboBoxItem)cmbD3d.SelectedItem).Content}";

            if (!string.IsNullOrWhiteSpace(txtXml.Text)) cmd += $" -xml \"{txtXml.Text}\"";
            if (!string.IsNullOrWhiteSpace(txtLog.Text)) cmd += $" -log \"{txtLog.Text}\"";

            if (txtDatastore.IsEnabled && !string.IsNullOrWhiteSpace(txtDatastore.Text))
            {
                if (!txtDatastore.Text.Equals(@"C:\Windows\Performance\WinSAT\Datastore", StringComparison.OrdinalIgnoreCase))
                {
                    cmd += $" -datastore \"{txtDatastore.Text}\"";
                }
            }

            txtPreview.Text = cmd;
        }

        private void Timer_Tick(object? sender, EventArgs e)
        {
            var ts = _stopwatch.Elapsed;
            txtTimer.Text = string.Format("{0:00}:{1:00}:{2:00}", ts.Hours, ts.Minutes, ts.Seconds);
        }

        private void BtnRun_Click(object sender, RoutedEventArgs e)
        {
            bool isAdmin = new WindowsPrincipal(WindowsIdentity.GetCurrent()).IsInRole(WindowsBuiltInRole.Administrator);
            if (!isAdmin)
            {
                MessageBox.Show("WinSAT requires Administrator privileges to run hardware assessments. Please run this application as Administrator.", "Admin Required", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            string cmdLine = txtPreview.Text;
            if (string.IsNullOrEmpty(cmdLine)) return;

            string args = cmdLine.Substring(7).Trim();
            string separator = new string('-', 48);
            string nl = Environment.NewLine;

            txtOutput.Text = $"EXECUTING: {cmdLine}{nl}{separator}{nl}";
            txtStatus.Text = "Running...";
            txtStatusIcon.Text = "O";
            txtStatusIcon.Foreground = Brushes.Orange;
            txtExecutedStatus.Text = $"Last Command: {cmdLine}";

            btnRun.IsEnabled = false;
            btnStop.IsEnabled = true;

            _stopwatch.Restart();
            _timer.Start();

            _activeProcess = new Process();
            _activeProcess.StartInfo.FileName = "winsat.exe";
            _activeProcess.StartInfo.Arguments = args;
            _activeProcess.StartInfo.UseShellExecute = false;
            _activeProcess.StartInfo.RedirectStandardOutput = true;
            _activeProcess.StartInfo.RedirectStandardError = true;
            _activeProcess.StartInfo.CreateNoWindow = true;
            _activeProcess.EnableRaisingEvents = true;

            _activeProcess.OutputDataReceived += (s, args) => {
                if (args.Data != null) {
                    Dispatcher.Invoke(() => {
                        txtOutput.AppendText(args.Data + Environment.NewLine);
                        txtOutput.ScrollToEnd();
                    });
                }
            };

            _activeProcess.ErrorDataReceived += (s, args) => {
                if (args.Data != null) {
                    Dispatcher.Invoke(() => {
                        txtOutput.AppendText(args.Data + Environment.NewLine);
                        txtOutput.ScrollToEnd();
                    });
                }
            };

            _activeProcess.Exited += (s, args) => {
                Dispatcher.Invoke(() => {
                    _timer.Stop();
                    btnRun.IsEnabled = true;
                    btnStop.IsEnabled = false;

                    int exitCode = _activeProcess.ExitCode;
                    if (exitCode == 0) {
                        txtOutput.AppendText($"{nl}{separator}{nl}PROCESS COMPLETED SUCCESSFULLY.");
                        txtStatus.Text = "Ready";
                        txtStatusIcon.Text = "V";
                        txtStatusIcon.Foreground = Brushes.Green;
                    } else {
                        txtOutput.AppendText($"{nl}{separator}{nl}PROCESS EXITED WITH CODE: {exitCode}");
                        txtStatus.Text = "Error";
                        txtStatusIcon.Text = "X";
                        txtStatusIcon.Foreground = Brushes.Red;
                    }
                    txtOutput.ScrollToEnd();

                    _activeProcess.Dispose();
                    _activeProcess = null;
                });
            };

            try
            {
                _activeProcess.Start();
                _activeProcess.BeginOutputReadLine();
                _activeProcess.BeginErrorReadLine();
            }
            catch (Exception ex)
            {
                txtOutput.AppendText($"{nl}FAILED TO START: {ex.Message}");
                btnRun.IsEnabled = true;
                btnStop.IsEnabled = false;
                _timer.Stop();
            }
        }

        private void BtnStop_Click(object sender, RoutedEventArgs e)
        {
            if (_activeProcess != null && !_activeProcess.HasExited)
            {
                string separator = new string('-', 48);
                string nl = Environment.NewLine;
                txtOutput.AppendText($"{nl}{separator}{nl}TERMINATING PROCESS...");
                try {
                    _activeProcess.Kill();
                } catch {
                    // Ignore kill errors
                }
            }
        }

        private void NavAbout_Click(object sender, RoutedEventArgs e)
        {
            string aboutXaml = @"
            <Window xmlns=""http://schemas.microsoft.com/winfx/2006/xaml/presentation""
                    xmlns:x=""http://schemas.microsoft.com/winfx/2006/xaml""
                    Title=""About winsat-gui"" Height=""460"" Width=""480"" WindowStartupLocation=""CenterScreen"" ResizeMode=""NoResize"" Background=""#FAFAFA"" FontFamily=""Segoe UI"">
                <Grid Margin=""25"">
                    <Grid.RowDefinitions>
                        <RowDefinition Height=""Auto""/>
                        <RowDefinition Height=""Auto""/>
                        <RowDefinition Height=""*""/>
                        <RowDefinition Height=""Auto""/>
                    </Grid.RowDefinitions>
                    
                    <TextBlock Grid.Row=""0"" Text=""winsat-gui"" FontSize=""26"" FontWeight=""Bold"" Foreground=""#005A9E""/>
                    <TextBlock Grid.Row=""1"" Text=""Version 1.1 | by Joshua Dwight"" FontSize=""14"" Foreground=""#555"" Margin=""0,2,0,15""/>
                    
                    <StackPanel Grid.Row=""2"">
                        <TextBlock Text=""A modern, high-performance WPF graphical interface for the Windows System Assessment Tool (WinSAT). This tool eliminates the need for complex command-line syntax while maintaining full feature parity, making system benchmarking intuitive and accessible."" TextWrapping=""Wrap"" Margin=""0,0,0,15"" LineHeight=""20""/>
                        
                        <TextBlock Text=""Powerful Features:"" FontWeight=""SemiBold"" Margin=""0,0,0,8""/>
                        <TextBlock Text=""- Full GUI mapping of all native WinSAT commands&#x0a;- Asynchronous, non-blocking execution engine&#x0a;- Real-time console output streaming&#x0a;- Dynamic command generation &amp; validation&#x0a;- Context-aware integrated help system"" TextWrapping=""Wrap"" LineHeight=""20"" Margin=""10,0,0,15""/>
                        
                        <TextBlock><Hyperlink x:Name=""lnkAboutGithub""><Run Text=""https://github.com/joshdwight101""/></Hyperlink></TextBlock>
                    </StackPanel>
                    
                    <Button x:Name=""btnAboutClose"" Grid.Row=""3"" Content=""OK"" Width=""80"" Height=""30"" HorizontalAlignment=""Right"" Background=""#0078D7"" Foreground=""White"" BorderThickness=""0"" Cursor=""Hand""/>
                </Grid>
            </Window>";

            var aboutWindow = (Window)XamlReader.Parse(aboutXaml);
            
            var btnAboutClose = (Button)aboutWindow.FindName("btnAboutClose");
            btnAboutClose.Click += (s, args) => aboutWindow.Close();
            
            var lnkAboutGithub = (Hyperlink)aboutWindow.FindName("lnkAboutGithub");
            lnkAboutGithub.RequestNavigate += (s, args) => {
                Process.Start(new ProcessStartInfo("https://github.com/joshdwight101") { UseShellExecute = true });
                args.Handled = true;
            };

            aboutWindow.ShowDialog();
        }
    }
}