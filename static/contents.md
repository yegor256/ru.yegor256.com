---
layout: page
title: "Содержание"
date: 2017-03-02
permalink: contents.html
description: |
  Полное содержание блога, список всех статей
  опубликованных, начиная с ноября 2016-го года.
image: http://www.yegor256.com/images/yegor-is-presenting.png
keywords:
  - политика
  - егор бугаенко
  - украинская политика
  - политика по-русски
---

Всего: {{ site.posts.size }}.

{% for post in site.posts %}
  <div>
    <div>
      <a href="{{ post.url }}">
        <span itemprop="name headline mainEntityOfPage">{{ post.title }}</span>
      </a>
    </div>
    <ul class="subline">
      <li>
        <time itemprop="datePublished dateModified" datetime="{{ post.date | date_to_xmlschema }}">
          {% assign m = post.date | date: "%-m" %}
          {{ post.date | date: "%-d" }}
          {% case m %}
            {% when '1' %}января
            {% when '2' %}февраля
            {% when '3' %}марта
            {% when '4' %}апреля
            {% when '5' %}мая
            {% when '6' %}июня
            {% when '7' %}июля
            {% when '8' %}августа
            {% when '9' %}сентября
            {% when '10' %}октября
            {% when '11' %}ноября
            {% when '12' %}декабря
          {% endcase %}
          {{ post.date | date: "%Y" }}
        </time>
      </li>
      <li>
        <i class="icon icon-comments"></i>
        <a href="{{ site.url }}{{ post.url }}#disqus_thread" itemprop="discussionUrl">комментарии</a>
      </li>
    </ul>
  </div>
{% endfor %}

