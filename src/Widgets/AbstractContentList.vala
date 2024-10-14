/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

/**
 * @class AbstractContentList
 * @brief An abstract base class for content list widgets in the Tuner application.
 *
 * The AbstractContentList class serves as a foundation for creating content list
 * widgets. It extends Gtk.FlowBox and provides a basic structure for implementing
 * content lists with a customizable item count.
 *
 * @extends Gtk.FlowBox
 */
public abstract class Tuner.AbstractContentList : Gtk.FlowBox {

    /**
     * @property item_count
     * @brief The number of items in the content list.
     *
     * This abstract property must be implemented by derived classes to provide
     * getter and setter methods for managing the item count of the content list.
     */
    public abstract uint item_count { get; set; }

}
