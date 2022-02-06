/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

public abstract class Tuner.AbstractContentList : Gtk.FlowBox {

    public abstract uint item_count { get; set; }

}