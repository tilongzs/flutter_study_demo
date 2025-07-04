class Signal {
	final List<SignalHelper> _helpers = List<SignalHelper>.empty(growable: true);

	List<SignalHelper> get helpers => List.unmodifiable(_helpers);
	int get numListeners => _helpers.length;

	void add(Function fnc) {
		_add(fnc, false);
	}

	void addOnce(Function fnc) {
		_add(fnc, true);
	}

	void addOnlyOnce(Function fnc) {
		removeAll();
		_add(fnc, true);
	}

	void _add(Function fnc, bool once) {
		SignalHelper e = SignalHelper(fnc, once: once);
		_helpers.add(e);
	}

	void remove(Function fnc) {
		_helpers.removeWhere((element) => element.fnc == fnc);
	}

	void removeAll() {
		_helpers.clear();
	}

	void dispatch([arguments]) {
		final helpers = List<SignalHelper>.from(_helpers);
		final toRemove = <SignalHelper>[];

		for (var e in helpers) {
			Function f = e.fnc;
			if (arguments != null) {
				f(arguments);
			} else {
				f();
			}

			if (e.once) {
				toRemove.add(e);
			}
		}

		_helpers.removeWhere((e) => toRemove.contains(e));
	}
}

class SignalHelper {
	final bool once;
	final Function fnc;

	SignalHelper(this.fnc, {this.once = false});
}