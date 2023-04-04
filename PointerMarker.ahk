;@Ahk2Exe-Base ../v2/AutoHotkey64.exe
#Requires AutoHotkey v2
#SingleInstance Force

SetWinDelay(0)
CoordMode("Mouse", "Screen")

; https://www.autohotkey.com/docs/v2/misc/DPIScaling.htm#Workarounds
DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")

class PointerMarkerApp
{
    ; 設定
    iniFile := A_ScriptDir . "\PointerMarker.ini"
    iniFileDefault := A_ScriptDir . "\PointerMarker.ini.default"
    cfg := {}

    ; マウス座標、モニタ情報
    x := -1
    y := -1
    m := {no: -1}
    movedAt := 0

    ; マーカー
    marker := ""
    shownAt := 0

    __New()
    {
        ; 設定ファイル読込
        if (!FileExist(this.iniFile)) {
            FileCopy(this.iniFileDefault, this.iniFile)
        }
        this.cfg.size := IniRead(this.iniFile, "Marker", "Size", 80)
        this.cfg.color := IniRead(this.iniFile, "Marker", "Color", "FF0000")
        this.cfg.transparent := IniRead(this.iniFile, "Marker", "Transparent", 64)
        this.cfg.fadeOutDelay := IniRead(this.iniFile, "Marker", "FadeOutDelay", 0.5)
        this.cfg.fadeOutDuration := IniRead(this.iniFile, "Marker", "FadeOutDuration", 0.5)
        this.cfg.triggerMonitorEdge := IniRead(this.iniFile, "TriggerMonitorEdge", "Enable", "true") == "true"
        this.cfg.triggerMonitorChange := IniRead(this.iniFile, "TriggerMonitorChange", "Enable", "true") == "true"
        this.cfg.triggerWakeup := IniRead(this.iniFile, "TriggerWakeup", "Enable", "true") == "true"
        this.cfg.sleepTime := IniRead(this.iniFile, "TriggerWakeup", "SleepTime", 10)

        ; タスクトレイメニュー設定
        A_IconTip := "ポインタマーカー"
        TraySetIcon("tray.png")
        A_TrayMenu.Delete("&Suspend Hotkeys")
        A_TrayMenu.Delete("&Pause Script")
        A_TrayMenu.Delete("E&xit")
        A_TrayMenu.Add("設定ファイル編集", (*) => Run(this.iniFile))
        A_TrayMenu.Add("再起動", (*) => Reload())
        A_TrayMenu.Add("終了", (*) => ExitApp())
    }

    Start()
    {
        ; マーカー作成
        ; -DPIScale https://www.autohotkey.com/docs/v2/misc/DPIScaling.htm#Gui_DPI_Scaling
        ; +E0x02000000(WS_EX_COMPOSITED) +E0x00080000(WS_EX_LAYERED) ちらつき防止
        ; +E0x00000020(WS_EX_TRANSPARENT) 透過ウィンドウ
        this.marker := Gui("+AlwaysOnTop +ToolWindow -Caption -DPIScale +E0x02000000 +E0x00080000 +E0x00000020")
        this.marker.BackColor := this.cfg.color
        this.marker.Show(Format("W{1} H{2} HIDE", this.cfg.size, this.cfg.size))
        WinSetRegion(Format("0-0 W{1} H{2} E", this.cfg.size, this.cfg.size), this.marker)

        ; タイマー
        SetTimer(() => this.OnTimer(), 10)
    }

    OnTimer()
    {
        triggered := this.Watch()
        if (triggered || this.shownAt) {
            this.marker.Move(this.x - this.cfg.size // 2, this.y - this.cfg.size // 2)
            if (triggered) {
                WinSetTransparent(this.cfg.transparent, this.marker)
                if (this.shownAt == 0) {
                    this.marker.Show("NA")
                }
                this.shownAt := A_TickCount
            }
            this.Fadeout()
        }
    }

    Watch()
    {
        triggered := false
        MouseGetPos(&x, &y)
        if (this.x != x || this.y != y) {
            m := this.GetCurrentMonitor(x, y)
            ; モニタの端に接触、または離れる場合
            if (this.cfg.triggerMonitorEdge && m.no != -1) {
                if (x == m.left || x == m.right - 1 ||
                    y == m.top || y == m.bottom - 1 ||
                    this.x == m.left || this.x == m.right - 1 ||
                    this.y == m.top || this.y == m.bottom - 1
                ) {
                    triggered := true
                }
            }
            ; 別のモニタに移動した場合
            if (this.cfg.triggerMonitorChange && m.no != -1) {
                if (this.m.no != m.no) {
                    triggered := true
                }
            }
            ; ポインタがsleepTime(秒)以上停止後に移動した場合
            if (this.cfg.triggerWakeup) {
                elapsed := A_TickCount - this.movedAt
                if (elapsed > this.cfg.sleepTime * 1000) {
                    triggered := true
                }
            }
            this.x := x
            this.y := y
            this.m := m
            this.movedAt := A_TickCount
        }
        return triggered
    }

    GetCurrentMonitor(x, y)
    {
        m := {no: -1}
        Loop MonitorGetCount()
        {
            MonitorGet(A_Index, &left, &top, &right, &bottom)
            if (left <= x && top <= y && x < right && y < bottom) {
                m.no := A_Index
                m.left := left
                m.top := top
                m.right := right
                m.bottom := bottom
                break
            }
        }
        return m
    }

    Fadeout()
    {
        elapsed := A_TickCount - this.shownAt
        if (elapsed > this.cfg.fadeOutDelay * 1000) {
            if (this.cfg.fadeOutDuration) {
                d := this.cfg.transparent / (this.cfg.fadeOutDuration * 1000)
                t := elapsed - this.cfg.fadeOutDelay * 1000
                transparent := Max(Round(this.cfg.transparent - d * t), 0)
            } else {
                transparent := 0
            }
            WinSetTransparent(transparent, this.marker)
            if (transparent == 0) {
                this.marker.Show("HIDE")
                this.shownAt := 0
            }
        }
    }
}

app := PointerMarkerApp()
app.Start()
