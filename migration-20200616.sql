CREATE TABLE item_counts (
  id INTEGER PRIMARY KEY NOT NULL,
  count int,
  item_id int NOT NULL,
  FOREIGN KEY (item_id) REFERENCES items(id)
);
CREATE INDEX item_counts_idx_item_id ON item_counts (item_id);
