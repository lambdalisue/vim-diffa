def _vim_diffa_unified_define():
    import re
    region_pattern = re.compile(
        '^\@\@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@'
    )

    def parse_unified_region(line):
        m = region_pattern.match(line)
        if not m:
            raise Exception('An invalid format line "%s" was found.' % line)
        sstart = m.group(1)
        send   = m.group(2)
        dstart = m.group(3)
        dend   = m.group(4)
        # find correct action
        if send == '0':
            action = 'a'
        elif dend == '0':
            action = 'd'
        else:
            action = 'c'
        # find correct endpoint
        if send and send != '0':
            send = ',%d' % (int(sstart) + int(send) - 1)
        else:
            send = ''
        if dend and dend != '0':
            dend = ',%d' % (int(dstart) + int(dend) - 1)
        else:
            dend = ''
        return '%s%s%s%s%s' % (sstart, send, action, dstart, dend)

    def parse_unified(unified):
        normal = []
        for line in unified:
            if line.startswith('+++') or line.startswith('---'):
                continue
            elif region_pattern.match(line):
                normal.append(parse_unified_region(line))
            elif line.startswith('-'):
                normal.append('< ' + line[1:])
            elif line.startswith('+'):
                if normal[-1].startswith('< '):
                    normal.append('---')
                normal.append('> ' + line[1:])
        return normal

    def format_exception():
        exc_type, exc_obj, tb = sys.exc_info()
        f = tb.tb_frame
        lineno = tb.tb_lineno
        filename = f.f_code.co_filename
        exception = "%s: %s at %s:%d" % (
            exc_obj.__class__.__name__,
            exc_obj, filename, lineno,
        )
        return exception

    return parse_unified, format_exception

try:
    import vim
    # Success. Assume it is executed from Vim
    _vim_diffa_unified_parse_unified, _vim_diffa_unified_format_exception = \
            _vim_diffa_unified_define()
    try:
        _vim_diffa_unified_parse_unified_result = \
                _vim_diffa_unified_parse_unified(vim.eval('a:unified'))
    except:
        _vim_diffa_unified_parse_unified_result = \
                _vim_diffa_unified_format_exception()
except ImportError:
    parse_unified, format_exception = _vim_diffa_unified_define()
