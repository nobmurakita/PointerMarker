;#NoTrayIcon
#SingleInstance, Force

; マーカーの大きさ(px)
MarkerSize := 80

; マーカーの色
MarkerColor := "FF0000"

; マーカーの透明度(0～255)
MarkerTransparent := 128

; マーカーがフェードアウトを開始するまでの遅延時間(ミリ秒)
MarkerFadeOutDelay := 500

; マーカーがフェードアウトを開始してから消えるまでの時間(ミリ秒)
MarkerFadeOutTime := 500

; マウスポインタがモニタの端に接触した時にマーカーを表示する(true/false)
MarkerTriggerMoniterEdge := true

; マウスポインタが異なるモニタに移動した時にマーカーを表示する(true/false)
MarkerTriggerMoniterChange := true

; マウスポインタが一定時間停止後に動いた時にマーカーを表示する(秒)
; 0で無効
MarkerTriggerWakeup := 10

SetWinDelay, 0
CoordMode, Mouse, Screen

Gui, +LastFound +AlwaysOnTop +ToolWindow -Caption +E0x00000020
Gui, Color, %MarkerColor%
Gui, Show, W%MarkerSize% H%MarkerSize% Hide
WinSet, Region, E W%MarkerSize% H%MarkerSize% 0-0

SetTimer, OnTimer, 10
Exit

OnTimer:
    MouseGetPos, x, y
    WatchMouse(x, y)
    Animation(x, y)
    return

WatchMouse(x, y) {
    global MarkerTriggerWakeup
    global MarkerTriggerMoniterEdge
    global MarkerTriggerMoniterChange
    static prev_m, prev_x, prev_y, moved_tickcount := A_TickCount
    if (prev_x != x || prev_y != y) {
        m := CurrentMonitor(x, y, left, top, right, bottom)
        if (MarkerTriggerMoniterEdge) {
            if (x == left || y == top
                || x == right - 1 || y == bottom - 1) {
                ShowMarker()
            } else if (prev_x == left || prev_y == top
                || prev_x == right - 1 || prev_y == bottom - 1) {
                ShowMarker()
            }
        }
        if (MarkerTriggerMoniterChange) {
            if (prev_m && prev_m != m) {
                ShowMarker()
            }
        }
        if (MarkerTriggerWakeup) {
            delay := MarkerTriggerWakeup * 1000
            if (A_TickCount - moved_tickcount > delay) {
                ShowMarker()
            }
            moved_tickcount := A_TickCount
        }
        prev_m := m, prev_x := x, prev_y := y
    }
}

CurrentMonitor(x, y, ByRef left, ByRef top, ByRef right, ByRef bottom) {
    SysGet, MonitorCount, MonitorCount
    Loop, % MonitorCount
    {
        SysGet, m_, Monitor, % A_Index
        if (m_Left <= x && m_Top <= y && x < m_Right && y < m_Bottom) {
            left := m_Left, top := m_Top, right := m_Right, bottom := m_Bottom
            return A_Index
        }
    }
}

ShowMarker() {
    global MarkerTransparent, CurrentTransparent, MarkerShown
    if (!MarkerShown) {
        Gui, Show, NA
    }
    if (CurrentTransparent != MarkerTransparent) {
        Gui, +LastFound
        WinSet, Transparent, % MarkerTransparent
    }
    CurrentTransparent := MarkerTransparent
    MarkerShown := A_TickCount
}

Animation(x, y) {
    global MarkerSize, MarkerTransparent
    global MarkerFadeOutDelay, MarkerFadeOutTime
    global CurrentTransparent, MarkerShown
    if (MarkerShown) {
        Gui, +LastFound
        WinMove, x - MarkerSize // 2, y - MarkerSize // 2
        if (A_TickCount - MarkerShown > MarkerFadeOutDelay) {
            if (MarkerFadeOutTime) {
                d := MarkerTransparent / MarkerFadeOutTime
                time := A_TickCount - MarkerShown - MarkerFadeOutDelay
                CurrentTransparent := MarkerTransparent - d * time
            } else {
                CurrentTransparent := 0
            }
            if (0 < CurrentTransparent) {
                WinSet, Transparent, % Round(CurrentTransparent)
            } else {
                CurrentTransparent := MarkerShown := 0
                Gui, Hide
            }
        }
    }
}
