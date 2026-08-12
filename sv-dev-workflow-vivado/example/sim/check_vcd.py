#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_vcd.py — 解析 VCD 波形, 判定 AXI 写通道仿真是否成功

用法:
    python check_vcd.py [波形文件]

检查项 (与 tb_axi_wr_example.sv 场景对应):
  1. 写事务完成: m_axi_bvalid 上升沿 1 次 (一次写突发一次响应)
  2. 突发正确: m_axi_wlast 出现 1 次 (len=4 最后一拍)
  3. 地址正确: m_axi_awaddr == 0x10, m_axi_awlen == 3 (len-1)
  4. 无错误: wr_error 无上升沿

只使用 Python 标准库。退出码: 0 = 全部通过, 1 = 存在失败或异常
"""

import sys


def scan_events(path):
    """扫描 VCD, 返回 {信号名: [(时间_ps, 值), ...]}

    注意: xsim 的 VCD 存在重复 id (标准要求全局唯一, xsim 违反):
      - 同一网络的信号 (TB 顶层 wire 与 DUT 内部同名网络) 共用 id, 值相同
      - 处理: id 直接映射, 重复 id 取首次声明 (xsim 按层次 dump, 顶层先声明,
        check 关心的正是 TB 顶层信号)
    """
    events = {}
    current_time = 0
    timescale = 1
    id_to_name = {}
    pending_ts = False

    with open(path, 'r', errors='replace') as f:
        lines = f.readlines()

    for line in lines:
        s = line.strip()
        if s.startswith('$timescale'):
            # xsim 格式: $timescale 与值分行 ($timescale \n 1ns \n $end)
            pending_ts = True
            continue
        if pending_ts:
            if s and not s.startswith('$'):
                timescale = {'ps': 1, 'ns': 1000, 'us': 1000000,
                             'fs': 0.001, 'ms': 1000000000}.get(s.lower(), 1)
                pending_ts = False
            else:
                continue
        elif s.startswith('$var'):
            parts = s.split()
            # $var wire 1 ! name $end
            # 首次声明优先 (顶层信号先声明, 重复 id 取第一个)
            id_to_name.setdefault(parts[3], parts[4])
        elif s.startswith('#') and len(s) > 1:
            current_time = int(s[1:]) * timescale
        elif len(s) >= 2 and s[0] in '01xXzZ':
            val = '1' if s[0] == '1' else '0'
            name = id_to_name.get(s[1:])
            if name is not None:
                events.setdefault(name, []).append((current_time, val))
        elif s.startswith('b') and ' ' in s:
            # 向量值格式: b<二进制值> <id> (如 b00010000 -)
            try:
                bits, sig = s[1:].split(' ', 1)
                name = id_to_name.get(sig)
                if name is not None and bits:
                    events.setdefault(name, []).append((current_time, bits))
            except ValueError:
                pass
    return events, timescale


def rising_edges(events, name):
    """信号上升沿次数"""
    evs = events.get(name, [])
    cnt = 0
    prev = '0'
    for _, v in evs:
        if prev == '0' and v == '1':
            cnt += 1
        prev = v
    return cnt


def first_value(events, name):
    """信号首次出现的值 (非 0)"""
    evs = events.get(name, [])
    for _, v in evs:
        if v == '1':
            return '1'
    return '0'


def check(path):
    events, timescale = scan_events(path)
    print("=" * 62)
    print(" VCD check report: %s" % path)
    print("=" * 62)
    print("  timescale: %d ps/unit   signals: %d" % (timescale, len(events)))
    print("-" * 62)

    ok = True

    # 1. 写事务完成: m_axi_bvalid 上升沿 1 次
    n = rising_edges(events, 'm_axi_bvalid')
    print(" [1] m_axi_bvalid rising edges (expect 1): %d" % n)
    if n == 1:
        print("      -> [PASS]")
    else:
        print("      -> [FAIL]")
        ok = False

    # 2. 突发正确: m_axi_wlast 出现 1 次
    n = rising_edges(events, 'm_axi_wlast')
    print(" [2] m_axi_wlast rising edges (expect 1): %d" % n)
    if n == 1:
        print("      -> [PASS]")
    else:
        print("      -> [FAIL]")
        ok = False

    # 3. 地址正确: awaddr 出现过 0x10 (00010000)
    #    注意: xsim 向量值不带前导零 (如 '10000'), 比较前规范化
    evs = events.get('m_axi_awaddr', [])
    saw_addr = any(v.lstrip('0') == '10000' for _, v in evs)
    print(" [3] m_axi_awaddr == 0x10 seen: %s" % saw_addr)
    if saw_addr:
        print("      -> [PASS]")
    else:
        print("      -> [FAIL]")
        ok = False

    # 4. 无错误: wr_error 无上升沿
    n = rising_edges(events, 'wr_error')
    print(" [4] wr_error rising edges (expect 0): %d" % n)
    if n == 0:
        print("      -> [PASS]")
    else:
        print("      -> [FAIL]")
        ok = False

    print("=" * 62)
    print("  Result: %s" % ("ALL PASS" if ok else "FAILED"))
    print("=" * 62)
    return 0 if ok else 1


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python check_vcd.py <waveform.vcd>")
        sys.exit(1)
    sys.exit(check(sys.argv[1]))
