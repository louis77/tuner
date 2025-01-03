/**
 * SPDX-FileCopyrightText: Copyright © 2020-2024 Louis Brauer <louis@brauer.family>
 * SPDX-FileCopyrightText: Copyright © 2024 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file ListFlowBox.vala
 *
 * @class ListFlowBox
 * @brief An base class for content list widgets in the Tuner application.
 *
 * The ListFlowBox class serves as a foundation for creating content list
 * widgets. It extends Gtk.FlowBox and provides a basic structure for implementing
 * content lists with a customizable item count.
 *
 * @extends Gtk.FlowBox
 */
public class Tuner.ListFlowBox : Gtk.FlowBox 
{

    /**
     * @property item_count
     * @brief The number of items in the content list.
     *
     * This abstract property must be implemented by derived classes to provide
     * getter and setter methods for managing the item count of the content list.
     */
    public uint item_count { get; set; }

} // ListFlowBox
